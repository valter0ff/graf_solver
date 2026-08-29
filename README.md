# Puzzle Runner

Цей проект знаходить найдовший ланцюжок чисел, де кожне наступне число продовжує попереднє за двома останніми цифрами.

## Запуск локально

```bash
ruby puzzle_solver.rb source.txt
```

## Запуск через Docker

```bash
docker build -t puzzle-runner .
docker run --rm -it puzzle-runner
```

Або без попереднього build:

```bash
docker run --rm -v "$PWD":/app -w /app ruby:3.2-slim ruby puzzle_solver.rb source.txt
```
