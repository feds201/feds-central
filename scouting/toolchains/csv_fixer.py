import csv
import sys
import os
import re
import chardet
from rich.console import Console
from rich.panel import Panel
from rich.progress import Progress
from rich.prompt import Prompt

console = Console()

def detect_encoding(file_path):
    """Detect the encoding of a file using chardet"""
    with open(file_path, 'rb') as f:
        result = chardet.detect(f.read(10000))
    return result['encoding']

def detect_delimiter(file_path, encoding='utf-8'):
    """
    Manually detect the delimiter in a CSV file by analyzing the first few lines
    """
    possible_delimiters = [',', ';', '\t', '|']
    delimiter_counts = {d: 0 for d in possible_delimiters}
    
    try:
        with open(file_path, 'r', encoding=encoding, errors='replace') as f:
            # Read first 5 lines or fewer if the file is smaller
            lines = []
            for _ in range(5):
                line = f.readline().strip()
                if not line:
                    break
                lines.append(line)
        
        # Count occurrences of each delimiter in each line
        for line in lines:
            for delimiter in possible_delimiters:
                delimiter_counts[delimiter] += line.count(delimiter)
        
        # Find the delimiter with the most consistent count across lines
        consistency = {}
        for delimiter, count in delimiter_counts.items():
            if count == 0:
                continue
                
            # Check if count per line is consistent
            counts_per_line = [line.count(delimiter) for line in lines]
            if min(counts_per_line) > 0:  # Delimiter appears in every line
                std_dev = (sum((c - (count/len(lines)))**2 for c in counts_per_line) / len(lines))**0.5
                consistency[delimiter] = std_dev
        
        if consistency:
            # Return the delimiter with the lowest standard deviation (most consistent)
            best_delimiter = min(consistency.items(), key=lambda x: x[1])[0]
            return best_delimiter
        else:
            # If no consistent delimiter found, return the one with highest count
            best_delimiter = max(delimiter_counts.items(), key=lambda x: x[1])[0]
            if delimiter_counts[best_delimiter] > 0:
                return best_delimiter
    except Exception as e:
        console.print(f"[yellow]Error during delimiter detection: {e}[/yellow]")
    
    # Default to comma if detection fails
    return ','

def preprocess_csv_content(file_path, encoding='utf-8'):
    """
    Preprocess the CSV content to handle potential issues before parsing
    """
    try:
        with open(file_path, 'r', encoding=encoding, errors='replace') as f:
            content = f.read()
            
        # Remove any BOM markers
        if content.startswith('\ufeff'):
            content = content[1:]
            
        # Handle common issues
        
        # Remove commented lines (lines starting with //)
        content = re.sub(r'^//.*$', '', content, flags=re.MULTILINE)
        
        # Handle quoted fields with embedded commas properly
        # This is a basic attempt - CSV parsing is complex for edge cases
        
        return content
    except Exception as e:
        console.print(f"[bold red]Error preprocessing file: {e}[/bold red]")
        return None

def count_fields_in_header(content, delimiter):
    """Count the number of fields in the header line"""
    first_line = content.split('\n', 1)[0]
    # Handle quoted fields properly
    in_quote = False
    field_count = 1  # Start with 1 because n delimiters = n+1 fields
    
    for char in first_line:
        if char == '"':
            in_quote = not in_quote
        elif char == delimiter and not in_quote:
            field_count += 1
            
    return field_count

def fix_csv_file(input_path, output_path=None, delimiter=None, encoding=None):
    """
    Fix a CSV file with inconsistent field counts by properly handling quoted fields.
    
    Parameters:
    -----------
    input_path : str
        Path to the input CSV file
    output_path : str, optional
        Path to the output fixed CSV file
    delimiter : str, optional
        CSV delimiter character
    encoding : str, optional
        File encoding
    
    Returns:
    --------
    str
        Path to the fixed CSV file
    """
    if output_path is None:
        base_path, ext = os.path.splitext(input_path)
        output_path = f"{base_path}_fixed{ext}"

    try:
        with Progress() as progress:
            task = progress.add_task("[cyan]Processing CSV file...", total=100)
            progress.update(task, completed=10)
            
            # Detect file encoding if not provided
            if not encoding:
                encoding = detect_encoding(input_path)
                console.print(f"[green]Detected file encoding: {encoding}[/green]")
            
            # Detect delimiter if not provided
            if not delimiter:
                delimiter = detect_delimiter(input_path, encoding)
                console.print(f"[green]Detected delimiter: '{delimiter}'[/green]")
            
            # First process the file to clean it up
            content = preprocess_csv_content(input_path, encoding)
            if not content:
                return None
                
            progress.update(task, completed=30)
            
            # Write preprocessed content to a temporary file
            temp_file = f"{output_path}.temp"
            with open(temp_file, 'w', encoding=encoding, newline='') as f:
                f.write(content)
                
            # Count expected columns from header
            expected_column_count = count_fields_in_header(content, delimiter)
            console.print(f"[green]Detected {expected_column_count} columns in header[/green]")
            
            progress.update(task, completed=40)
            
            # Now process the file line by line
            rows = []
            problem_rows = []
            
            # Define a custom dialect for the CSV parser
            class CustomDialect(csv.Dialect):
                delimiter = delimiter
                quotechar = '"'
                doublequote = True
                skipinitialspace = True
                lineterminator = '\n'
                quoting = csv.QUOTE_MINIMAL
            
            # Register the dialect
            csv.register_dialect('custom', CustomDialect)
            
            # Open and process the temporary file
            with open(temp_file, 'r', encoding=encoding, newline='') as infile:
                reader = csv.reader(infile, dialect='custom')
                
                # Read the header
                try:
                    header = next(reader)
                except StopIteration:
                    console.print("[bold red]Error: Empty or invalid CSV file[/bold red]")
                    return None
                
                progress.update(task, completed=50)
                
                # Process all rows
                for i, row in enumerate(reader, start=2):  # Start at 2 for 1-indexed line numbers (header is line 1)
                    try:
                        if len(row) != expected_column_count:
                            problem_rows.append((i, len(row)))
                            # Try to fix the row
                            if len(row) > expected_column_count:
                                # Join extra fields into the last expected field
                                fixed_row = row[:expected_column_count-1]
                                # Join the excess fields into the last field
                                combined_field = delimiter.join(row[expected_column_count-1:])
                                # Remove any quotes that might cause issues
                                if combined_field.startswith('"') and combined_field.endswith('"'):
                                    combined_field = combined_field[1:-1]
                                fixed_row.append(combined_field)
                                rows.append(fixed_row)
                            else:
                                # If fewer columns than expected, pad with empty strings
                                rows.append(row + [''] * (expected_column_count - len(row)))
                        else:
                            rows.append(row)
                    except Exception as e:
                        console.print(f"[yellow]Warning: Error processing row {i}: {e}[/yellow]")
                        # Add the row as-is with potential issues
                        rows.append(row)
                
                progress.update(task, completed=80)
            
            # Clean up temp file
            try:
                os.remove(temp_file)
            except:
                pass
            
            # Write the fixed data
            with open(output_path, 'w', newline='', encoding=encoding) as outfile:
                writer = csv.writer(outfile, dialect='custom')
                writer.writerow(header)
                writer.writerows(rows)
                
                progress.update(task, completed=100)
            
            if problem_rows:
                console.print(f"[yellow]Found and fixed issues in {len(problem_rows)} rows:[/yellow]")
                # Show at most 10 problem rows to avoid flooding the console
                for line_num, col_count in problem_rows[:10]:
                    console.print(f"  Line {line_num}: Found {col_count} fields (expected {expected_column_count})")
                if len(problem_rows) > 10:
                    console.print(f"  ... and {len(problem_rows) - 10} more rows")
            
            console.print(Panel(f"[bold green]CSV file fixed successfully![/bold green]\nSaved to: {output_path}", 
                               title="Success", border_style="green"))
            
            return output_path
            
    except Exception as e:
        console.print(f"[bold red]Error fixing CSV file: {e}[/bold red]")
        import traceback
        console.print(traceback.format_exc())
        return None

if __name__ == "__main__":
    console.print("[bold cyan]CSV Fixer Tool[/bold cyan]", justify="center")
    console.print("[yellow]Fixes CSV files with inconsistent field counts[/yellow]\n")
    
    try:
        if len(sys.argv) > 1:
            input_path = sys.argv[1]
            output_path = sys.argv[2] if len(sys.argv) > 2 else None
        else:
            input_path = console.input("[cyan]Enter path to CSV file: [/cyan]")
            output_path = console.input("[cyan]Enter path for fixed CSV file (leave blank for auto-naming): [/cyan]")
            if not output_path:
                output_path = None
        
        # Ask if the user wants to manually specify delimiter and encoding
        manual_settings = Prompt.ask(
            "Do you want to manually specify delimiter and encoding?", 
            choices=["y", "n"], 
            default="n"
        )
        
        delimiter = None
        encoding = None
        
        if manual_settings.lower() == "y":
            delimiter = Prompt.ask(
                "Enter delimiter character", 
                choices=[",", ";", "tab", "|", "other"], 
                default=","
            )
            if delimiter == "tab":
                delimiter = "\t"
            elif delimiter == "other":
                delimiter = console.input("Enter custom delimiter: ")
                
            encoding = Prompt.ask(
                "Enter file encoding", 
                choices=["utf-8", "utf-8-sig", "latin-1", "cp1252", "other"], 
                default="utf-8"
            )
            if encoding == "other":
                encoding = console.input("Enter custom encoding: ")
        
        fix_csv_file(input_path, output_path, delimiter, encoding)
    except KeyboardInterrupt:
        console.print("\n[bold yellow]Operation cancelled by user[/bold yellow]")
    except Exception as e:
        console.print(f"[bold red]An unexpected error occurred: {e}[/bold red]")
