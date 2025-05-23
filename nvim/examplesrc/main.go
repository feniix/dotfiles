package main

import (
	"fmt"
	"time"
)

// Person struct with JSON tags
type Person struct {
	Name string `json:"name"`
	Age  int    `json:"age"`
}

// String method implements Stringer interface
func (p Person) String() string {
	return fmt.Sprintf("Person{Name: %s, Age: %d}", p.Name, p.Age)
}

// calculateSum demonstrates basic function with conditionals
func calculateSum(a, b int) int {
	if a > 0 {
		return a + b
	}
	return 0
}

// processAsync demonstrates goroutines and channels
func processAsync(nums []int) <-chan int {
	results := make(chan int, len(nums))

	go func() {
		defer close(results)
		for _, num := range nums {
			results <- num * 2
		}
	}()

	return results
}

func main() {
	// Test struct and methods
	person := Person{Name: "Alice", Age: 30}
	fmt.Println(person)

	// Test function call
	sum := calculateSum(5, 3)
	fmt.Printf("Sum: %d\n", sum)

	// Test goroutines and channels
	numbers := []int{1, 2, 3, 4, 5}
	results := processAsync(numbers)

	// Process results with timeout
	for {
		select {
		case result, ok := <-results:
			if !ok {
				return
			}
			fmt.Printf("Result: %d\n", result)
		case <-time.After(1 * time.Second):
			fmt.Println("Timeout")
			return
		}
	}
}
