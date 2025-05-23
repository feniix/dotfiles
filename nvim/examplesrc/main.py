#!/usr/bin/env python3
"""
Example Python file for testing language support features.
Includes classes, functions, decorators, type hints, and error handling.
"""

import asyncio
import json
from dataclasses import dataclass
from typing import List, Optional, Dict, Any
from datetime import datetime
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


@dataclass
class Person:
    """A person with basic information."""
    name: str
    age: int
    email: Optional[str] = None
    
    def is_adult(self) -> bool:
        return self.age >= 18
    
    def to_dict(self) -> Dict[str, Any]:
        return {"name": self.name, "age": self.age, "email": self.email}


def timing_decorator(func):
    """Decorator to measure execution time."""
    import time
    def wrapper(*args, **kwargs):
        start = time.time()
        result = func(*args, **kwargs)
        print(f"{func.__name__} took {time.time() - start:.4f}s")
        return result
    return wrapper


class Calculator:
    """Simple calculator with history."""
    
    def __init__(self):
        self.history: List[str] = []
    
    @timing_decorator
    def add(self, a: float, b: float) -> float:
        result = a + b
        self.history.append(f"{a} + {b} = {result}")
        return result


async def fetch_data(url: str) -> Dict[str, str]:
    """Simulate async data fetching."""
    await asyncio.sleep(0.1)
    return {"url": url, "data": f"Data from {url}"}


async def process_urls(urls: List[str]) -> List[Dict[str, str]]:
    """Process URLs concurrently."""
    tasks = [fetch_data(url) for url in urls]
    return await asyncio.gather(*tasks)


def validate_config(config: Dict[str, Any]) -> bool:
    """Validate configuration."""
    required = ["name", "version"]
    if not all(key in config for key in required):
        raise ValueError("Missing required keys")
    return True


async def main():
    """Main function demonstrating Python features."""
    # Test dataclass
    person = Person("Alice", 30, "alice@example.com")
    print(f"Person: {person}")
    print(f"Is adult: {person.is_adult()}")
    
    # Test class and decorator
    calc = Calculator()
    result = calc.add(10, 5)
    print(f"Result: {result}")
    
    # Test async
    urls = ["api1.com", "api2.com", "api3.com"]
    data = await process_urls(urls)
    print(f"Fetched {len(data)} items")
    
    # Test list comprehension
    squares = [x**2 for x in range(5) if x % 2 == 0]
    print(f"Even squares: {squares}")
    
    # Test context manager
    with open("/tmp/test.txt", "w") as f:
        f.write("Hello, World!")


if __name__ == "__main__":
    asyncio.run(main()) 