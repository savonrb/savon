module URI
  class Generic

    # Returns whether the URI hints to SSL.
    def ssl?
      /^https/ === @scheme
    end

  end
end
