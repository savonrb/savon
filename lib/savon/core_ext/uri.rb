module URI
  class Generic

    # Returns whether the URI hints to SSL.
    def ssl?
      @scheme.starts_with? "https"
    end

  end
end
