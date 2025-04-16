#!/usr/bin/env bash
# shellcheck shell=bash

# Tests for NETWORKING FUNCTIONS from sh-globals.sh

# Source the main library relative to the tests directory
Include "sh-globals.sh"

Describe "NETWORKING FUNCTIONS"
  Describe "is_url_reachable()"
    # Create a mock for curl and wget
    BeforeEach 'setup_curl_wget_mocks'
    
    setup_curl_wget_mocks() {
      # Override command_exists to indicate curl is available
      command_exists() {
        if [[ "$1" == "curl" ]]; then
          return 0
        elif [[ "$1" == "wget" ]]; then
          return 1
        else
          command -v "$1" &>/dev/null
        fi
      }
      
      # Create a mock curl function
      curl() {
        local url=""
        local timeout=""
        
        # Parse arguments
        while [[ $# -gt 0 ]]; do
          case "$1" in
            --max-time)
              timeout="$2"
              shift 2
              ;;
            --head|--silent|--fail)
              shift
              ;;
            *)
              url="$1"
              shift
              ;;
          esac
        done
        
        # Mock behavior based on URL
        if [[ "$url" == *"success"* ]]; then
          return 0
        elif [[ "$url" == *"timeout"* ]]; then
          sleep 1
          return 28  # Curl timeout code
        else
          return 1
        fi
      }
    }
    
    It "returns success for a reachable URL"
      When call is_url_reachable "https://example.com/success" 5
      The status should be success
    End

    It "returns failure for an unreachable URL"
      When call is_url_reachable "https://example.com/failure" 2
      The status should be failure
    End
  End

  Describe "get_external_ip()"
    BeforeEach 'setup_ip_mock'
    
    setup_ip_mock() {
      # Override command_exists
      command_exists() {
        if [[ "$1" == "curl" ]]; then
          return 0
        elif [[ "$1" == "wget" ]]; then
          return 1
        else
          command -v "$1" &>/dev/null
        fi
      }
      
      # Create a mock curl function for IP
      curl() {
        if [[ "$1" == "-s" && ("$2" == "https://ifconfig.me" || "$2" == "https://api.ipify.org") ]]; then
          echo "192.168.1.100"  # Mock IP address
          return 0
        else
          return 1
        fi
      }
    }
    
    It "returns an external IP address"
      When call get_external_ip
      The status should be success
      The output should equal "192.168.1.100"
    End
  End

  Describe "is_port_open()"
    BeforeEach 'setup_nc_mock'
    
    setup_nc_mock() {
      # Create a mock nc function
      nc() {
        local host=""
        local port=""
        local timeout=""
        
        # Parse arguments
        while [[ $# -gt 0 ]]; do
          case "$1" in
            -z)
              shift
              ;;
            -w)
              timeout="$2"
              shift 2
              ;;
            *)
              # Assume the remaining args are host and port
              if [[ -z "$host" ]]; then
                host="$1"
              else
                port="$1"
              fi
              shift
              ;;
          esac
        done
        
        # Mock behavior based on host and port
        if [[ "$host" == "open.example.com" || "$port" == "80" ]]; then
          return 0  # Success - port is open
        else
          return 1  # Failure - port is closed
        fi
      }
    }
    
    It "checks if a port is open"
      When call is_port_open "open.example.com" 80 2
      The status should be success
    End
    
    It "checks if a port is closed"
      When call is_port_open "closed.example.com" 9999 1
      The status should be failure
    End
  End
End 