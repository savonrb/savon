module SpecSupport

  def mock_stdout
    original_stdout = $stdout

    stdout = StringIO.new
    $stdout = stdout

    yield

    $stdout = original_stdout
    stdout
  end

  def silence_stdout
    original_stdout = $stdout
    $stdout = StringIO.new

    result = yield

    $stdout = original_stdout
    result
  end

end
