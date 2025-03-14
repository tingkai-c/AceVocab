const apiKey: string = process.env.EXPO_PUBLIC_GEMINI_API_KEY || "";

class LLMservice {
  private static async _makeGeminiRequest(prompt: string): Promise<string> {
    const requestBody = {
      contents: [
        {
          role: "user",
          parts: [{ text: prompt }],
        },
      ],
    };

    const response = await fetch(
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-lite:generateContent",
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-goog-api-key": apiKey,
        },
        body: JSON.stringify(requestBody),
      }
    );

    if (!response.ok) {
      const errorText = await response.text();
      const errorMessage = `Gemini API request failed with status ${response.status} for prompt "${prompt}": ${errorText}`;
      console.log(errorMessage);
      throw new Error(errorMessage);
    }

    const data = await response.json();
    if (
      data.candidates &&
      data.candidates.length > 0 &&
      data.candidates[0].content &&
      data.candidates[0].content.parts &&
      data.candidates[0].content.parts.length > 0
    ) {
      return data.candidates[0].content.parts[0].text.trim();

    } else {
      // Handle the case where the response doesn't have the expected structure
      const errorMessage = "Unexpected response structure from Gemini API";
      console.log(errorMessage);
      throw new Error(errorMessage);
    }
  }

  static async generateVocabQuestion(correctWord: string): Promise<{ question: string; choices: string[]; correctAnswer: number }> {
    const prompt = `Make a “fill in the blank” question with the word “${correctWord}”  The sentence should be in undergraduate level.

Also generate another three wrong words to make it a multi-choice question.

Make sure the sentence have adequate context in order to ensure only one answer is applicable.

Return the sentence and options in the following json format:

{”question”: “”, “wrongChoices”: [””, ””, ””], "correctWord": ""}`; // Added correctWord to the expected JSON
    console.log("Generating question")
    const responseString = await this._makeGeminiRequest(prompt);
    console.log("parsing json")

    // Remove Markdown code block delimiters (if present)
    const cleanedResponseString = responseString.replace(/^```json\s*|\s*```$/g, '');

    let parsedResponse;
    try {
      parsedResponse = JSON.parse(cleanedResponseString);
    } catch (error) {
      console.log("Failed to parse JSON response:", cleanedResponseString)
      const errorMessage = `Failed to parse JSON response from Gemini: ${error}.  Response was: ${cleanedResponseString}`;
      console.log(errorMessage);
      throw new Error(errorMessage);
    }
    console.log(parsedResponse)

    // Validate the structure
    if (
      !parsedResponse ||
      typeof parsedResponse.question !== 'string' ||
      !Array.isArray(parsedResponse.choices) ||
      typeof parsedResponse.correctWord !== 'string'
    ) {
      const errorMessage = `Invalid response structure from Gemini: ${cleanedResponseString}`;
      console.log(errorMessage);
      throw new Error(errorMessage);
    }

    // Specific check for choices length *before* trying to add the correct word
    if (parsedResponse.choices.length < 3) {
      const errorMessage = `Gemini returned too few choices: ${cleanedResponseString}`;
      console.log(errorMessage);
      throw new Error(errorMessage);
    }

    // Add the correct word to the choices array, if it's not already there.
    if (!parsedResponse.choices.includes(parsedResponse.correctWord)) {
      // Replace a random incorrect choice with the correct word.  This is important
      // because sometimes Gemini *doesn't* include the correct word in the choices!

      // Ensure we have *at least* 3 choices before adding the correct one.
      while (parsedResponse.choices.length < 3) {
        parsedResponse.choices.push("placeholder"); // Add placeholders if needed
      }

      const randomIndex = Math.floor(Math.random() * parsedResponse.choices.length);
      parsedResponse.choices[randomIndex] = parsedResponse.correctWord;
    }

    // *After* potentially adding the correct word, check the length again.
    if (parsedResponse.choices.length !== 4) {
      const errorMessage = `Gemini returned an incorrect number of choices: ${cleanedResponseString}`;
      console.log(errorMessage);
      throw new Error(errorMessage);
    }

    const correctAnswerIndex = parsedResponse.choices.indexOf(parsedResponse.correctWord);

    if (correctAnswerIndex === -1) {
      const errorMessage = `Correct word "${correctWord}" not found in choices: ${parsedResponse.choices}`;
      console.log(errorMessage);
      throw new Error(errorMessage);
    }

    console.log(parsedResponse)

    return {
      question: parsedResponse.question,
      choices: parsedResponse.choices,
      correctAnswer: correctAnswerIndex,
    };
  }

  static async askLLM(prompt: string): Promise<string> {
    return this._makeGeminiRequest(prompt);
  }
}

export default LLMservice;


