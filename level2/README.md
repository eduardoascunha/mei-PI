# Context-Aware SQL Generation Results

Experimental results for LLM-based SQL generation using TPC-H and TPC-C.

## Repository Structure
```
├── TPC-H/
│   ├── gemini/      # Gemini 2.5 Pro results
│   ├── gpt/         # GPT-5.1 results
│   ├── deepseek/    # DeepSeek v3.1 results
│   └── llama/       # Llama Maverick 4 results
│
└── TPC-C/
    ├── gemini/      # Gemini 2.5 Pro results
    ├── gpt/         # GPT-5.1 results
    ├── deepseek/    # DeepSeek v3.1 results
    └── llama/       # Llama Maverick 4 results
```

Each model folder contains results for different prompting methods:
- Zero-shot
- Zero-shot with Reasoning
- Few-shot (with different configurations)
- Few-shot with Reasoning
