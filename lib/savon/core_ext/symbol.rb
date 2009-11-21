class Symbol

  # Converts the Symbol to snake_case.
  def snakecase
    to_s.snakecase.to_sym
  end

end
