# encoding: utf-8

test "output of successful run" do
  expected = "•"

  out = %x{./bin/cutest test/fixtures/success.rb}

  assert out[expected]
end

test "exit code of successful run" do
  %x{./bin/cutest test/fixtures/success.rb}
  assert_equal 0, $?.to_i
end

test "output of failed run" do
  expected = "failed assertion"

  out = %x{./bin/cutest test/fixtures/failure.rb}

  assert out[expected]
end

test "output of failed run" do
  expected = "RuntimeError"

  out = %x{./bin/cutest test/fixtures/exception.rb}

  assert out[expected]
end

test "exit code of failed run" do
  %x{./bin/cutest test/fixtures/failure.rb}

  assert $?.to_i != 0
end

test "output of custom assertion" do
  expected = "Cutest::AssertionFailed"

  out = %x{./bin/cutest test/fixtures/fail_custom_assertion.rb}

  assert out[expected]
end

test "output of failure in nested file" do
  expected = "Cutest::AssertionFailed"

  out = %x{./bin/cutest test/fixtures/failure_in_loaded_file.rb}

  assert out[expected]
end

test "output of failure outside block" do
  expected = "Cutest::AssertionFailed"

  out = %x{./bin/cutest test/fixtures/outside_block.rb}

  assert out[expected]
end

test "only runs given scope name" do
  out = %x{./bin/cutest test/fixtures/only_run_given_scope_name.rb -s scope}

  assert out =~ /This is raised/
end

test "runs by given scope and test names" do
  %x{./bin/cutest test/fixtures/only_run_given_scope_name.rb -s scope -t test}

  assert_equal 0, $?.to_i
end
