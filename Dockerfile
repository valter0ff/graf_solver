FROM ruby:3.2-slim

WORKDIR /app

COPY puzzle_solver.rb /app/
COPY source.txt /app/

CMD ["ruby", "puzzle_solver.rb", "source.txt"]
