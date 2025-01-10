import subprocess
import ollama
import sys
from ai_commit.commit_agent import run_command
from ai_commit.generate_llm_message import generate_message
# Define a system prompt to guide the AI for code reviews
system_prompt = """
You are an AI code review assistant. Your task is to review provided code diffs and provide actionable feedback.
Focus on:
1. Identifying potential issues (e.g., security, performance, readability).
2. Suggesting improvements where possible.
3. Providing clear and concise feedback for each change.

Your feedback should:
- Be professional and constructive.
- Avoid vague comments and be specific about the issue.
- Use technical terminology relevant to the programming language or framework.

Output format:
1. Summarize the overall quality of the changes.
2. Provide detailed feedback in bullet points for specific issues.
"""


def get_git_diff():
    return run_command(['git', 'diff', '--unified=0'])

def review_code():
    diff = get_git_diff()
    if not diff:
        print("No changes detected. Please make changes and try again.")
        sys.exit(0)

    feedback = generate_message(diff, "llama3.2:1b", system_prompt)

    print("\n\nCode Review Feedback:")
    print(feedback)