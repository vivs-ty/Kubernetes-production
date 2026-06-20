
#!/usr/bin/env bats

# Runs before each test to set up the environment
setup() {
    # Load the script to be tested into the environment
    source ./check_endpoint.sh
}

@test "Endpoint check succeeds for a valid, reachable URL" {
    # Run the function
    run check_endpoint "https://www.google.com"
    
    # Assert the exit status is 0 (Success)
    [ "$status" -eq 0 ]
    # Assert the output matches expectation
    [[ "$output" == *"Connection successful"* ]]
}

@test "Endpoint check fails gracefully for an invalid domain" {
    run check_endpoint "https://this-domain-definitely-does-not-exist.local"
    
    # Assert the exit status is 1 (Error)
    [ "$status" -eq 1 ]
    # Assert the error message is correct
    [[ "$output" == *"Host unreachable"* ]]
}

@test "Endpoint check catches missing arguments" {
    run check_endpoint
    
    [ "$status" -eq 1 ]
    [[ "$output" == *"Error: URL parameter missing"* ]]
}

setup() {
    # Adjusted path to go up one level and into src/bash/
    source ./src/bash/check_endpoint.sh
}
