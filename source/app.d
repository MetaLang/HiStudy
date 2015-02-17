import std.algorithm;
import std.conv;
import std.exception;
import std.file;
import std.getopt;
import std.functional;
import std.stdio;
import std.string;
import std.json;
import std.path;
import std.random;
import std.string;

string getResponse()
{
    return readln().strip().chomp().toLower();
}

alias wrapWriteln = pipe!(wrap, std.stdio.writeln);

alias CmdFunc = void function(size_t, size_t, JSONValue);

enum defaultQuestionDir = "questions";

void main(string[] args)
{
    string jsonFile;
    args.getopt("file|f", &jsonFile);

    enforce(jsonFile.length, "No question file specified");
    string jsonFilePath = jsonFile;
    //If it's just a filename, it must be the name
    //of a file in the questions directory
    if (!jsonFile.canFind(dirSeparator))
    {
        jsonFilePath = buildPath(absolutePath(defaultQuestionDir), jsonFile);
    }
    enforce(jsonFilePath.exists, "File '%s' does not exist".format(jsonFilePath));

    auto jsonText = readText(jsonFilePath).strip().chomp();
    auto json = jsonText.parseJSON();

    string response;
    while (!response.among!("start", "random", "quit"))
    {
        wrapWriteln(`Type "start" to do the question sets in order, or type "random" `
                        ~ `to do them in random order. Type "quit" to quit.`);
        response = getResponse();
    }

    if (response == "start")
    {
        outerFor: foreach (size_t i, questionSet; json["questionSets"])
        {
            writeln();
            wrapWriteln("This question set is about " ~ questionSet["focus"].str ~ ". "
                            ~ `Type "hint" to get a hint for the current question. `
                            ~ `Type "question" to see the question again. `
                            ~ `Type "skip" to display the answer and go to the next question. `
                            ~ `Type "skip set" to skip this question set. `
                            ~ `Type "quit" to quit.`);
            innerFor: foreach (size_t j, question; questionSet["questions"])
            {
                writeln();
                writeln("Question ", j + 1, ", Set ", i + 1);
                wrapWriteln(question["text"].str);

                while (true)
                {
                    response = getResponse();
                    writeln();
                    if (response == "hint")
                    {
                        if (question["hint"].str.length == 0)
                        {
                            wrapWriteln("There is no hint for this question");
                        }
                        else
                        {
                            wrapWriteln("Hint: " ~ question["hint"].str);
                        }
                    }
                    else if (response == "question")
                    {
                        writeln("Question ", j + 1, ", Set ", i + 1);
                        wrapWriteln(question["text"].str);
                    }
                    else if (response == "skip set")
                    {
                        break innerFor;
                    }
                    else if (response == "skip")
                    {
                        if (question["answer"].type != JSON_TYPE.STRING)
                        {
                            wrapWriteln("The answer is: " ~ question["answer"].to!string());
                        }
                        else
                        {
                            wrapWriteln("The answer is: " ~ question["answer"].str);
                        }
                        wrapWriteln("Continuing on to the next question");
                        break;
                    }
                    else if (response == "quit")
                    {
                        break outerFor;
                    }
                    else
                    {
                        bool correctAnswer = false;
                        if (question["answer"].type != JSON_TYPE.STRING)
                        {
                            auto convertedAnswer = question["answer"].to!string();
                            correctAnswer = response == convertedAnswer;
                        }
                        else
                        {
                            correctAnswer = response == question["answer"].str;
                        }

                        if (correctAnswer)
                        {
                            wrapWriteln("Correct! Continuing on to the next question.");
                            break;
                        }
                        else
                        {
                            wrapWriteln("That answer was incorrect");
                        }
                    }
                }
            }

            while (true)
            {
                wrapWriteln(`End of this question set. Type "continue" to go on to the next set. `
                            ~ `Type "quit" to quit.`);
                response = getResponse();
                if (response == "continue")
                {
                    break;
                }
                else if (response == "quit")
                {
                    break outerFor;
                }
            }
        }

        writeln();
        wrapWriteln("That is the end of the question sets.");
        readln();
    }
    else if (response == "random")
    {
        wrapWriteln("This is not yet implemented");
        //foreach (questionset; json["questionsets"].array.randomcover())
        //{
        //}
    }
}
