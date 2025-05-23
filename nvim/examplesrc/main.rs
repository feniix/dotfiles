use std::collections::HashMap;
use std::fmt;
use std::io::{self, Write};
use std::sync::{Arc, Mutex};
use std::thread;
use std::time::{Duration, Instant};

#[derive(Debug, Clone)]
pub struct Person {
    pub name: String,
    pub age: u32,
    pub email: Option<String>,
}

impl Person {
    pub fn new(name: String, age: u32) -> Self {
        Self { name, age, email: None }
    }

    pub fn with_email(mut self, email: String) -> Self {
        self.email = Some(email);
        self
    }

    pub fn is_adult(&self) -> bool {
        self.age >= 18
    }
}

impl fmt::Display for Person {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match &self.email {
            Some(email) => write!(f, "{} ({}, {})", self.name, self.age, email),
            None => write!(f, "{} ({})", self.name, self.age),
        }
    }
}

#[derive(Debug)]
pub enum CalculationError {
    DivisionByZero,
    NegativeSquareRoot,
}

impl fmt::Display for CalculationError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            CalculationError::DivisionByZero => write!(f, "Division by zero"),
            CalculationError::NegativeSquareRoot => write!(f, "Negative square root"),
        }
    }
}

impl std::error::Error for CalculationError {}

pub struct Calculator {
    history: Vec<String>,
}

impl Calculator {
    pub fn new() -> Self {
        Self { history: Vec::new() }
    }

    pub fn add(&mut self, a: f64, b: f64) -> f64 {
        let result = a + b;
        self.history.push(format!("{} + {} = {}", a, b, result));
        result
    }

    pub fn divide(&mut self, a: f64, b: f64) -> Result<f64, CalculationError> {
        if b == 0.0 {
            return Err(CalculationError::DivisionByZero);
        }
        let result = a / b;
        self.history.push(format!("{} / {} = {}", a, b, result));
        Ok(result)
    }
}

// Generic function
pub fn find_max<T: PartialOrd + Copy>(slice: &[T]) -> Option<T> {
    slice.iter().copied().max()
}

// Trait example
pub trait Drawable {
    fn draw(&self) -> String;
}

pub struct Circle { radius: f64 }
pub struct Rectangle { width: f64, height: f64 }

impl Drawable for Circle {
    fn draw(&self) -> String {
        format!("Circle with radius {}", self.radius)
    }
}

impl Drawable for Rectangle {
    fn draw(&self) -> String {
        format!("Rectangle {}x{}", self.width, self.height)
    }
}

// Macro example
macro_rules! create_function {
    ($name:ident, $op:tt) => {
        pub fn $name(a: i32, b: i32) -> i32 { a $op b }
    };
}

create_function!(multiply, *);
create_function!(subtract, -);

fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Test struct and methods
    let person = Person::new("Alice".to_string(), 30)
        .with_email("alice@example.com".to_string());
    println!("Person: {}", person);
    println!("Is adult: {}", person.is_adult());

    // Test error handling
    let mut calc = Calculator::new();
    println!("10 + 5 = {}", calc.add(10.0, 5.0));
    
    match calc.divide(20.0, 4.0) {
        Ok(result) => println!("20 / 4 = {}", result),
        Err(e) => println!("Error: {}", e),
    }

    // Test generics
    let numbers = vec![3, 1, 4, 1, 5, 9];
    if let Some(max) = find_max(&numbers) {
        println!("Max: {}", max);
    }

    // Test traits
    let shapes: Vec<Box<dyn Drawable>> = vec![
        Box::new(Circle { radius: 5.0 }),
        Box::new(Rectangle { width: 10.0, height: 20.0 }),
    ];
    
    for shape in shapes {
        println!("{}", shape.draw());
    }

    // Test HashMap and pattern matching
    let mut scores = HashMap::new();
    scores.insert("Alice", 100);
    scores.insert("Bob", 85);
    
    for (name, score) in &scores {
        let grade = match score {
            90..=100 => "A",
            80..=89 => "B",
            70..=79 => "C",
            _ => "F",
        };
        println!("{}: {} ({})", name, score, grade);
    }

    // Test macros
    println!("6 * 7 = {}", multiply(6, 7));

    Ok(())
} 