import json
import os

def flatten_json(y):
    out = {}

    def flatten(x, name=''):
        if type(x) is dict:
            for a in x:
                flatten(x[a], name + a + '_')
        elif type(x) is list:
            i = 0
            for a in x:
                flatten(a, name + str(i) + '_')
                i += 1
        else:
            out[name[:-1]] = x

    flatten(y)
    return out

def process_json_input():
    count = 1
    while True:
        input_data = input(f"Enter JSON object {count} (or type 'exit' to stop): ")

        if input_data.lower() == 'exit':
            print("Exiting...")
            break

        try:
            # Step 1: Parse the input string into a Python dictionary
            json_data = json.loads(input_data)

            # Step 2: Flatten the JSON structure
            flattened_data = flatten_json(json_data)
            print(f"Flattened JSON: {flattened_data}")

            # Define the output file name
            output_filename = f"output_{count}.json"

            # Write the flattened JSON data to a file
            with open(output_filename, "w") as f:
                json.dump(flattened_data, f, indent=4)
            print(f"Processed and saved JSON object {count} as {output_filename}")

            count += 1

        except json.JSONDecodeError as e:
            print(f"Error processing JSON input: {e}. Please check the format.")

def main():
    if not os.path.exists("output_jsons"):
        os.makedirs("output_jsons")

    os.chdir("output_jsons")

    process_json_input()

if __name__ == '__main__':
    main()