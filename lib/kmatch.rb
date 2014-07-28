#require "kmatch/version"


class Kmatch
  _and = lambda { |a1, a2| a1 && a2 }
  _or = lambda { |a1, a2| a1 || a2 }

  @@operator_map = {
    '&' => _and,
    '|' => _or,
    '!' => lambda { |a1| !a1 },
    '^' => lambda { |a1, a2| a1 ^ a2 },
  }

  @@value_filter_map = {
      '==' => lambda { |a1, a2| a1 == a2 },
      '!=' => lambda { |a1, a2| a1 != a2 },
      '>' => lambda { |a1, a2| a1 > a2 },
      '>=' => lambda { |a1, a2| a1 >= a2 },
      '<' => lambda { |a1, a2| a1 < a2 },
      '<=' => lambda { |a1, a2| a1 <= a2 },
      '=~' => lambda { |reg, a1| a1.match(reg) }
  }

  @@key_filter_map = {
      '?' => lambda { |key, value| value.include?(key) },
      '!?' => lambda { |key, value| !value.include?(key) }
  }

  # Sets the pattern, performs validation on the pattern, and compiles its regexs if it has any.
  def initialize(pattern, suppress_key_errors=false)
    @_raw_pattern = pattern
    @_compiled_pattern = pattern
    @_suppress_key_errors = suppress_key_errors

    validate(@_compiled_pattern)

  end

  def is_operator(p)
    if p.length == 2 && @@operator_map.include?(p[0]) && p[1].kind_of?(Array)
      true
    else
      false
    end
  end

  def is_value_filter(p)
    if p.length == 3 && @@value_filter_map.include?(p[0])
      true
    else
      false
    end
  end

  def is_key_filter(p)
    if p.length == 2 && @@key_filter_map.include?(p[0])
      true
    else
      false
    end
  end

  # Recursively validate the pattern
  def validate(p)
    if is_operator(p)
      args_list(p).each { |operator_or_filter| validate(operator_or_filter)}
    elsif ! is_value_filter(p) and !is_key_filter(p)
      raise Exception("Not a valid operator or filter - #{p}")
    end
  end

  def args_list(p)
    if p[0] != '!'
      p[1]
    else
      [p[1]]
    end
  end

  # Returns true or false if the operator (&, |, or ! with filters, or ^ with filters) matches the value hash
  def match_operator(p, value)
    if p[0] == '!'
      @@operator_map[p[0]].call(_match(p[1], value))
    elsif p[0] == '^'
      @@operator_map[p[0]].call(_match(p[1][0], value), _match(p[1][1], value))
    else
      @@operator_map[p[0]].call(p[1].each {|operator_or_filter| _match(operator_or_filter, value)})
    end
  end

  # Returns true of false if value in the pattern p matches the filter.
  def match_value_filter(p, value)
    puts "p = #{p}"
    puts "value = #{value}"

    @@value_filter_map[p[0]].call(value[p[1]], p[2])
  end

  # Returns true of false if key in the pattern p and the value matches the filter.
  def match_key_filter(p, value)
    @@key_filter_map[p[0]].call(p[1], value)
  end


  def _match(p, value)
    if is_operator(p)
      match_operator(p, value)
    else
      begin
        if is_value_filter(p)
          return match_value_filter(p, value)
        else
          return match_key_filter(p, value)
        end
      rescue Exception
        if @_suppress_key_errors
          return false
        else
          raise
        end
      end
    end

  end

  # Matches the value to the pattern.
  def match(value)
    return _match(@_compiled_pattern, value)
  end

  private :is_operator, :is_value_filter, :is_key_filter, :validate, :args_list, :match_operator, :match_value_filter, :match_key_filter, :_match



end

