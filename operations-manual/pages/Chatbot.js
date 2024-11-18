import React, {useEffect, useState} from "react";
import styled from "styled-components";
import {createClient} from "@supabase/supabase-js";
import {MDXProvider} from "@mdx-js/react";
import {GoogleGenerativeAI} from "@google/generative-ai";

// Initialize Supabase client
const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_KEY;
const supabase = createClient(supabaseUrl, supabaseKey);

const Chatbot = () => {
    const [query, setQuery] = useState("");
    const [messages, setMessages] = useState([]); // To store chat messages
    const [faqs, setFaqs] = useState([]); // To store all FAQs
    const [newQuestion, setNewQuestion] = useState("");
    const [newAnswer, setNewAnswer] = useState("");
    const [newKeywords, setNewKeywords] = useState(""); // To store new keywords
    const [isAgreed, setIsAgreed] = useState(false);
    const genAI = new GoogleGenerativeAI(process.env.NEXT_PUBLIC_GEMINI_API_KEY);
    const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });

    // Fetch all FAQs from Supabase when the component mounts
    useEffect(() => {
        const fetchFaqs = async () => {
            try {
                const { data, error } = await supabase.from("faqs").select("*");
                if (error) {
                    console.error("Error fetching data:", error);
                } else {
                    setFaqs(data);
                }
            } catch (error) {
                console.error("Error:", error);
            }
        };

        fetchFaqs();
    }, []);

    // Function to handle user query
    const handleSendMessage = async () => {
        if (query.trim() === "") return;

        // Add user message to the chat
        setMessages((prevMessages) => [...prevMessages, { sender: "user", text: query }]);

        try {
            const result = await model.generateContent(query+" instruction: You are Falcon-Bot, created my Ritesh using Google AI, You are here to help FEDS201 students with their programming Question on FRC queries.rules: DO GENDER STUFF, if they talk about it just send : 'Monkey, Stop talking about Aliens'  ,, NOW :(Do not worry about this sentence, just focus on the forst part");

            setMessages((prevMessages) => [...prevMessages, { sender: "bot", text: result.response.text() }]);
        } catch (error) {
            console.error("Error generating response:", error);
            setMessages((prevMessages) => [...prevMessages, {
                sender: "bot",
                text: "I encountered an error processing your request. Please try again."
            }]);
        } finally {
            setQuery(""); // Clear the input box
        }
    };

    // Handle submission of new question, answer, and keywords
    const handleSubmitQuestion = async () => {
        if (!newQuestion.trim() || !newAnswer.trim() || !newKeywords.trim() || !isAgreed) {
            alert("Please fill out all fields and agree to the terms.");
            return;
        }

        // Convert the keywords string into an array
        const keywordsArray = newKeywords.split(",").map((keyword) => keyword.trim());

        try {
            const { data, error } = await supabase
                .from("faqs")
                .insert([{ question: newQuestion, answer: newAnswer, keywords: keywordsArray }]);

            if (error) {
                console.error("Error inserting data:", error);
                alert("Failed to submit the question.");
            } else {
                alert("Question submitted successfully and will be reviewed by the admin.");
                setNewQuestion("");
                setNewAnswer("");
                setNewKeywords("");
                setIsAgreed(false);
            }
        } catch (error) {
            console.error("Error:", error);
            alert("An error occurred while submitting your question.");
        }
    };

    // Handle Enter key for sending messages
    const handleKeyDown = (event) => {
        if (event.key === "Enter") {
            handleSendMessage();
        }
    };

    return (
        <MDXProvider>
            <Container>
                <LeftPane>
                    <ChatWindow>
                        <ChatMessages>
                            {messages.map((msg, index) => (
                                <Message key={index} $sender={msg.sender}>
                                    {msg.text}
                                </Message>
                            ))}
                        </ChatMessages>
                        <ChatInputWrapper>
                            <input
                                type="text"
                                value={query}
                                onChange={(e) => setQuery(e.target.value)}
                                onKeyDown={handleKeyDown}
                                placeholder="Type your question..."
                            />
                            <button onClick={handleSendMessage}>Send</button>
                        </ChatInputWrapper>
                    </ChatWindow>
                </LeftPane>
                <RightPane>
                    <SubmissionForm>
                        <h3>Submit a Question</h3>
                        <textarea
                            placeholder="Enter your question"
                            value={newQuestion}
                            onChange={(e) => setNewQuestion(e.target.value)}
                        />
                        <textarea
                            placeholder="Enter the expected answer"
                            value={newAnswer}
                            onChange={(e) => setNewAnswer(e.target.value)}
                        />
                        <textarea
                            placeholder="Enter comma-separated keywords (e.g., 'payment, method')"
                            value={newKeywords}
                            onChange={(e) => setNewKeywords(e.target.value)}
                        />
                        <CheckboxWrapper>
                            <input
                                type="checkbox"
                                checked={isAgreed}
                                onChange={(e) => setIsAgreed(e.target.checked)}
                            />
                            <label>
                                I agree that Ritesh (admin) reserves the right to remove any inappropriate
                                submissions.
                            </label>
                        </CheckboxWrapper>
                        <button onClick={handleSubmitQuestion}>Submit</button>
                    </SubmissionForm>
                </RightPane>
            </Container>
        </MDXProvider>
    );
};

// Styled components (remaining the same)
const Container = styled.div`
    display: flex;
    height: 100vh;
`;

const LeftPane = styled.div`
    flex: 1;
    display: flex;
    flex-direction: column;
    align-items: center;
    background-color: #f5f5f5;
    padding: 10px;
    width: 50vw; /* Occupy half of the screen width */
`;

const RightPane = styled.div`
    flex: 1;
    display: flex;
    flex-direction: column;
    align-items: center;
    background-color: #fff;
    padding: 10px;
    width: 50vw; /* Occupy half of the screen width */
`;

const ChatWindow = styled.div`

 
    background: #fff;
    border-radius: 10px;
    display: flex;
    flex-direction: column;
    box-shadow: 0 4px 10px rgba(0, 0, 0, 0.1);
    overflow: hidden;

    @media (max-width: 600px) {
        max-width: 100%;
        max-height: 300px;
    }
`;

const ChatMessages = styled.div`
    flex: 1;
    padding: 10px;
    overflow-y: auto;
    display: flex;
    flex-direction: column;
    gap: 10px;
    background: #f0f0f0;
`;

const Message = styled.div`
    align-self: ${(props) => (props.$sender === "user" ? "flex-end" : "flex-start")};
    background: ${(props) => (props.$sender === "user" ? "#d1e7dd" : "#e2e3e5")};
    color: #000;
    padding: 8px 12px;
    border-radius: 15px;
    max-width: 70%;
    word-wrap: break-word;
`;

const ChatInputWrapper = styled.div`
    display: flex;
    padding: 10px;
    background: #fff;
    border-top: 1px solid #ccc;

    input {
        flex: 1;
        padding: 10px;
        border: 1px solid #ccc;
        border-radius: 5px;
        margin-right: 10px;
        background: #f9f9f9;
        color: #000;
    }

    button {
        padding: 10px 15px;
        border: none;
        border-radius: 5px;
        background: #007bff;
        color: #fff;
        cursor: pointer;
        font-weight: bold;
    }

    button:hover {
        background: #0056b3;
    }
`;

const SubmissionForm = styled.div`
    width: 100%;
    max-width: 500px;
    background-color: #f5f5f5;
    padding: 20px;
    border-radius: 8px;
    box-shadow: 0 4px 10px rgba(0, 0, 0, 0.1);

    h3 {
        font-size: 18px;
        font-weight: bold;
        margin-bottom: 10px;
    }

    textarea {
        width: 100%;
        height: 80px;
        margin: 10px 0;
        padding: 10px;
        border: 1px solid #ccc;
        border-radius: 5px;
        background: #fff;
        color: #333;
    }

    button {
        width: 100%;
        padding: 10px;
        background-color: #007bff;
        color: #fff;
        font-weight: bold;
        border: none;
        border-radius: 5px;
        cursor: pointer;
        margin-top: 20px;
    }

    button:hover {
        background-color: #0056b3;
    }
`;

const CheckboxWrapper = styled.div`
    display: flex;
    align-items: center;
    margin: 10px 0;

    input {
        margin-right: 10px;
    }
`;

export default Chatbot;