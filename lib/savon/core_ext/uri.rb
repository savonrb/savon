module URI
  class HTTP

    # Returns whether the URI hints to SSL.
    def ssl?
      /^https/ === @scheme
    end

  end
end