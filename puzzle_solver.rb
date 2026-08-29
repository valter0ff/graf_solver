# frozen_string_literal: true

# Програма знаходить найдовший ланцюжок чисел, де кожне наступне число
# продовжує попереднє за двома останніми цифрами, а в результаті повертає
# максимальну послідовність фрагментів та з'єднану строку.
#
# Як запускати:
#   ruby puzzle_grok_final_refined.rb source.txt
#
# Якщо файл з числами не вказано, використовується source.txt за замовчуванням.

class DigitPuzzleSolver
  Edge = Struct.new(:prefix, :suffix, :number)

  # Ініціалізує граф: з кожного фрагмента будується ребро з префіксом і суфіксом.
  def initialize(numbers)
    @edges = numbers.map { |num| parse_edge(num) }
  end

  # Основний метод розв'язання: обробляє кожну компоненту окремо
  # і вибирає найдовший валідний шлях серед усіх компонент.
  def solve
    @best_path = []

    components.each do |edge_indices|
      start = eulerian_start(edge_indices)
      path = start ? hierholzer(start, edge_indices) : best_path_fallback(edge_indices)
      @best_path = path if path.size > @best_path.size
    end

    numbers = @best_path.map { |idx| @edges[idx].number }
    [numbers, join_chain(numbers)]
  end

  private

  # Перетворює рядок на ребро: перші 2 цифри — префікс, останні 2 — суфікс.
  def parse_edge(num)
    raise ArgumentError, "Некоректне число: #{num.inspect}" unless num.is_a?(String) && num.match?(/\A\d+\z/) && num.length >= 4

    Edge.new(num[0, 2], num[-2, 2], num)
  end

  # Збирає слабко пов'язані компоненти графа за допомогою Union-Find.
  def components
    parent = Hash.new { |h, k| h[k] = k }

    find = lambda do |node|
      while parent[node] != node
        parent[node] = parent[parent[node]]
        node = parent[node]
      end
      node
    end

    @edges.each do |edge|
      parent[find.call(edge.prefix)] = find.call(edge.suffix)
    end

    groups = Hash.new { |h, k| h[k] = [] }
    @edges.each_with_index do |edge, idx|
      groups[find.call(edge.prefix)] << idx
    end

    groups.values
  end

  # Якщо компонента є ейлерівським шляхом, повертає стартову вершину.
  # Якщо ні — повертає nil, щоб перейти до повного DFS-пошуку.
  def eulerian_start(edge_indices)
    out_deg = Hash.new(0)
    in_deg = Hash.new(0)

    edge_indices.each do |idx|
      edge = @edges[idx]
      out_deg[edge.prefix] += 1
      in_deg[edge.suffix] += 1
    end

    starts = []
    ends = []
    bad = 0

    (out_deg.keys | in_deg.keys).each do |node|
      diff = out_deg[node] - in_deg[node]
      case diff
      when 1 then starts << node
      when -1 then ends << node
      when 0 then nil
      else bad += 1
      end
    end

    return nil if bad.positive? || starts.size > 1 || ends.size > 1

    if starts.empty?
      edge_indices.each do |idx|
        node = @edges[idx].prefix
        return node if out_deg[node].positive?
      end
      nil
    else
      starts.first
    end
  end

  # Будує ейлерів цикл/шлях через алгоритм Геріхольцера для компоненти,
  # якщо для неї виконані умови ейлерового маршруту.
  def hierholzer(start, edge_indices)
    adj = build_adjacency(edge_indices)

    used = {}
    stack = [[start, nil]]
    path = []

    until stack.empty?
      node, incoming = stack.last

      while adj[node].any? && used[adj[node].last]
        adj[node].pop
      end

      if adj[node].empty?
        stack.pop
        path << incoming if incoming
      else
        idx = adj[node].pop
        next if used[idx]

        used[idx] = true
        stack << [@edges[idx].suffix, idx]
      end
    end

    path.reverse
  end

  # Резервний точний пошук: перебирає всі ребра компоненти, якщо немає
  # ейлерового маршруту. Зберігає максимальний шлях без агресивного відсікання.
  def best_path_fallback(edge_indices)
    adj = build_adjacency(edge_indices)
    used = {}
    best = []

    search = lambda do |node, path|
      best.replace(path.dup) if path.size > best.size

      adj[node].each do |idx|
        next if used[idx]

        used[idx] = true
        path << idx
        search.call(@edges[idx].suffix, path)
        path.pop
        used[idx] = false
      end
    end

    distinct_starts(edge_indices).each do |node|
      search.call(node, [])
    end

    best
  end

  # Створює список суміжності: вузол -> масив індексів ребер, що виходять з нього.
  def build_adjacency(edge_indices)
    adj = Hash.new { |h, k| h[k] = [] }
    edge_indices.each { |idx| adj[@edges[idx].prefix] << idx }
    adj
  end

  # Повертає множину стартових вузлів компоненти для повного перебору.
  def distinct_starts(edge_indices)
    edge_indices.map { |idx| @edges[idx].prefix }.uniq
  end

  # Склеює числа в одну строку: перше число повністю, інші — без перших двох цифр.
  def join_chain(numbers)
    return "" if numbers.empty?

    numbers[0] + numbers[1..].map { |num| num[2..] }.join
  end
end

if __FILE__ == $PROGRAM_NAME
  path = ARGV[0] || "source.txt"
  numbers = File.readlines(path, chomp: true).map(&:strip).reject(&:empty?)

  puts "Фрагментів: #{numbers.size}"
  t0 = Time.now
  best, chain = DigitPuzzleSolver.new(numbers).solve
  elapsed = (Time.now - t0).round(3)

  puts "Час: #{elapsed} с"
  puts "Довжина ланцюга: #{best.size}"
  puts "Числа: #{best.join(' → ')}"
  puts "Результат (#{chain.size} символів):"
  puts chain
end
