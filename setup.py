from setuptools import setup, find_packages

with open("README.md", "r", encoding="utf-8") as fh:
    long_description = fh.read()

setup(
    name="agent-balu",
    version="0.1.0",
    author="Prakan",
    author_email="prakan1684@gmail.com",
    description="A multifunctional AI Agent for Git operations, code reviews, and email management",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/prakan1684/Agent-Balu",
    packages=find_packages(),
    include_package_data=True,
    package_data={
        "ai_commit": ["prompts/*.txt"],
    },
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
    ],
    python_requires=">=3.6",
    install_requires=[
        "requests>=2.25.1",
        "ollama>=0.1.0",
        "SpeechRecognition>=3.8.1",
        "PyAudio>=0.2.11",
    ],
    entry_points={
        "console_scripts": [
            "ai-commit=ai_commit.cli:main",
        ],
    },
)
