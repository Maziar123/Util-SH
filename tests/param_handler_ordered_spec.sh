#!/usr/bin/env bash
# shellcheck shell=bash

Describe "param_handler.sh ordered array implementation"
  # Global arrays for parameter definitions
  declare -g -a STANDARD_PARAMS
  declare -g -a SINGLE_PARAMS
  declare -g -a TWO_PARAMS
  declare -g -a MANY_PARAMS

  # Setup - ensure we have param_handler.sh available
  setup() {
    # Load the param_handler.sh file relative to project root
    # shellcheck disable=SC1091
    . "./param_handler.sh"
    
    # Define standard parameters (used in most tests)
    STANDARD_PARAMS=(
      "graphic:VIRT_GRAPHIC:virt-graphic:Virtual graphics configuration"
      "video:VIRT_VIDEO:virt-video:Virtual video device settings"
      "render:RENDER:render:Rendering mode (software/virtual)"
      "gpu:GPU_VENDOR:gpu:GPU vendor (amd/nvidia/intel) or PCI address"
    )
    
    # Define single parameter array
    SINGLE_PARAMS=(
      "param:SINGLE_PARAM:single-param:Single parameter test"
    )
    
    # Define two parameter array
    TWO_PARAMS=(
      "first:FIRST_PARAM:param1:First parameter"
      "second:SECOND_PARAM:param2:Second parameter"
    )
    
    # Define many parameter array
    MANY_PARAMS=(
      "one:PARAM1:param1:First parameter"
      "two:PARAM2:param2:Second parameter"
      "three:PARAM3:param3:Third parameter"
      "four:PARAM4:param4:Fourth parameter"
      "five:PARAM5:param5:Fifth parameter"
      "six:PARAM6:param6:Sixth parameter"
      "seven:PARAM7:param7:Seventh parameter"
      "eight:PARAM8:param8:Eighth parameter"
    )
  }
  
  BeforeAll setup

  # Reset environment between tests
  cleanup() {
    unset VIRT_GRAPHIC VIRT_VIDEO RENDER GPU_VENDOR
    unset SINGLE_PARAM
    unset FIRST_PARAM SECOND_PARAM
    unset PARAM1 PARAM2 PARAM3 PARAM4 PARAM5 PARAM6 PARAM7 PARAM8
  }
  
  BeforeEach cleanup

  Context "when using named parameters"
    It "handles 1 named parameter correctly"
      When call param_handler::simple_handle STANDARD_PARAMS --virt-graphic "spice"
      The variable VIRT_GRAPHIC should equal "spice"
      The variable VIRT_VIDEO should equal ""
      The variable RENDER should equal ""
      The variable GPU_VENDOR should equal ""
      The status should be success
    End
    
    It "counts 1 named parameter correctly"
      param_handler::simple_handle STANDARD_PARAMS --virt-graphic "spice"
      When call param_handler::get_named_count
      The output should equal "1"
    End
    
    It "counts 0 positional parameters when using 1 named parameter"
      param_handler::simple_handle STANDARD_PARAMS --virt-graphic "spice"
      When call param_handler::get_positional_count
      The output should equal "0"
    End

    It "handles 2 named parameters correctly"
      When call param_handler::simple_handle STANDARD_PARAMS --virt-graphic "spice" --virt-video "qxl"
      The variable VIRT_GRAPHIC should equal "spice"
      The variable VIRT_VIDEO should equal "qxl"
      The variable RENDER should equal ""
      The variable GPU_VENDOR should equal ""
      The status should be success
    End
    
    It "counts 2 named parameters correctly"
      param_handler::simple_handle STANDARD_PARAMS --virt-graphic "spice" --virt-video "qxl"
      When call param_handler::get_named_count
      The output should equal "2"
    End
    
    It "counts 0 positional parameters when using 2 named parameters"
      param_handler::simple_handle STANDARD_PARAMS --virt-graphic "spice" --virt-video "qxl"
      When call param_handler::get_positional_count
      The output should equal "0"
    End

    It "handles all 4 named parameters correctly"
      When call param_handler::simple_handle STANDARD_PARAMS --virt-graphic "spice" --virt-video "qxl" --render "software" --gpu "nvidia"
      The variable VIRT_GRAPHIC should equal "spice"
      The variable VIRT_VIDEO should equal "qxl"
      The variable RENDER should equal "software"
      The variable GPU_VENDOR should equal "nvidia"
      The status should be success
    End
    
    It "counts 4 named parameters correctly"
      param_handler::simple_handle STANDARD_PARAMS --virt-graphic "spice" --virt-video "qxl" --render "software" --gpu "nvidia"
      When call param_handler::get_named_count
      The output should equal "4"
    End
    
    It "counts 0 positional parameters when using 4 named parameters"
      param_handler::simple_handle STANDARD_PARAMS --virt-graphic "spice" --virt-video "qxl" --render "software" --gpu "nvidia"
      When call param_handler::get_positional_count
      The output should equal "0"
    End
  End

  Context "when using positional parameters"
    It "handles 1 positional parameter correctly"
      When call param_handler::simple_handle STANDARD_PARAMS "spice"
      The variable VIRT_GRAPHIC should equal "spice"
      The variable VIRT_VIDEO should equal ""
      The variable RENDER should equal ""
      The variable GPU_VENDOR should equal ""
      The status should be success
    End
    
    It "counts 0 named parameters when using 1 positional parameter"
      param_handler::simple_handle STANDARD_PARAMS "spice"
      When call param_handler::get_named_count
      The output should equal "0"
    End
    
    It "counts 1 positional parameter correctly"
      param_handler::simple_handle STANDARD_PARAMS "spice"
      When call param_handler::get_positional_count
      The output should equal "1"
    End

    It "handles 2 positional parameters correctly"
      When call param_handler::simple_handle STANDARD_PARAMS "spice" "qxl"
      The variable VIRT_GRAPHIC should equal "spice"
      The variable VIRT_VIDEO should equal "qxl"
      The variable RENDER should equal ""
      The variable GPU_VENDOR should equal ""
      The status should be success
    End
    
    It "counts 0 named parameters when using 2 positional parameters"
      param_handler::simple_handle STANDARD_PARAMS "spice" "qxl"
      When call param_handler::get_named_count
      The output should equal "0"
    End
    
    It "counts 2 positional parameters correctly"
      param_handler::simple_handle STANDARD_PARAMS "spice" "qxl"
      When call param_handler::get_positional_count
      The output should equal "2"
    End

    It "handles all 4 positional parameters correctly"
      When call param_handler::simple_handle STANDARD_PARAMS "spice" "qxl" "software" "nvidia"
      The variable VIRT_GRAPHIC should equal "spice"
      The variable VIRT_VIDEO should equal "qxl"
      The variable RENDER should equal "software"
      The variable GPU_VENDOR should equal "nvidia"
      The status should be success
    End
    
    It "counts 0 named parameters when using 4 positional parameters"
      param_handler::simple_handle STANDARD_PARAMS "spice" "qxl" "software" "nvidia"
      When call param_handler::get_named_count
      The output should equal "0"
    End
    
    It "counts 4 positional parameters correctly"
      param_handler::simple_handle STANDARD_PARAMS "spice" "qxl" "software" "nvidia"
      When call param_handler::get_positional_count
      The output should equal "4"
    End
  End

  Context "when using mixed parameters"
    It "handles mixed parameters correctly (named first)"
      When call param_handler::simple_handle STANDARD_PARAMS --virt-graphic "spice" "qxl" --gpu "nvidia"
      The variable VIRT_GRAPHIC should equal "spice"
      The variable VIRT_VIDEO should equal "qxl"
      The variable RENDER should equal ""
      The variable GPU_VENDOR should equal "nvidia"
      The status should be success
    End
    
    It "counts named parameters correctly in mixed mode (named first)"
      param_handler::simple_handle STANDARD_PARAMS --virt-graphic "spice" "qxl" --gpu "nvidia"
      When call param_handler::get_named_count
      The output should equal "2"
    End
    
    It "counts positional parameters correctly in mixed mode (named first)"
      param_handler::simple_handle STANDARD_PARAMS --virt-graphic "spice" "qxl" --gpu "nvidia"
      When call param_handler::get_positional_count
      The output should equal "1"
    End

    It "handles mixed parameters correctly (positional first)"
      When call param_handler::simple_handle STANDARD_PARAMS "spice" --virt-video "qxl" --render "software" --gpu "nvidia"
      The variable VIRT_GRAPHIC should equal "spice"
      The variable VIRT_VIDEO should equal "qxl"
      The variable RENDER should equal "software"
      The variable GPU_VENDOR should equal "nvidia"
      The status should be success
    End
    
    It "counts named parameters correctly in mixed mode (positional first)"
      param_handler::simple_handle STANDARD_PARAMS "spice" --virt-video "qxl" --render "software" --gpu "nvidia"
      When call param_handler::get_named_count
      The output should equal "3"
    End
    
    It "counts positional parameters correctly in mixed mode (positional first)"
      param_handler::simple_handle STANDARD_PARAMS "spice" --virt-video "qxl" --render "software" --gpu "nvidia"
      When call param_handler::get_positional_count
      The output should equal "1"
    End

    It "handles complex mixed parameters correctly"
      When call param_handler::simple_handle STANDARD_PARAMS "spice" --virt-video "qxl" "software" --gpu "nvidia"
      The variable VIRT_GRAPHIC should equal "spice"
      The variable VIRT_VIDEO should equal "qxl"
      The variable RENDER should equal "software"
      The variable GPU_VENDOR should equal "nvidia"
      The status should be success
    End
    
    It "counts named parameters correctly in complex mixed mode"
      param_handler::simple_handle STANDARD_PARAMS "spice" --virt-video "qxl" "software" --gpu "nvidia"
      When call param_handler::get_named_count
      The output should equal "2"
    End
    
    It "counts positional parameters correctly in complex mixed mode"
      param_handler::simple_handle STANDARD_PARAMS "spice" --virt-video "qxl" "software" --gpu "nvidia"
      When call param_handler::get_positional_count
      The output should equal "2"
    End
  End
  
  Context "with varying parameter counts"
    It "handles a single named parameter correctly"
      When call param_handler::simple_handle SINGLE_PARAMS --single-param "value1"
      The variable SINGLE_PARAM should equal "value1"
      The status should be success
    End
    
    It "counts single named parameter correctly"
      param_handler::simple_handle SINGLE_PARAMS --single-param "value1"
      When call param_handler::get_named_count
      The output should equal "1"
    End
    
    It "handles a single positional parameter correctly"
      When call param_handler::simple_handle SINGLE_PARAMS "positional_value"
      The variable SINGLE_PARAM should equal "positional_value"
      The status should be success
    End
    
    It "counts single positional parameter correctly"
      param_handler::simple_handle SINGLE_PARAMS "positional_value"
      When call param_handler::get_positional_count
      The output should equal "1"
    End
    
    It "handles two named parameters correctly"
      When call param_handler::simple_handle TWO_PARAMS --param1 "first_value" --param2 "second_value"
      The variable FIRST_PARAM should equal "first_value"
      The variable SECOND_PARAM should equal "second_value"
      The status should be success
    End
    
    It "counts two named parameters correctly"
      param_handler::simple_handle TWO_PARAMS --param1 "first_value" --param2 "second_value"
      When call param_handler::get_named_count
      The output should equal "2"
    End
    
    It "handles two positional parameters correctly"
      When call param_handler::simple_handle TWO_PARAMS "first_positional" "second_positional"
      The variable FIRST_PARAM should equal "first_positional"
      The variable SECOND_PARAM should equal "second_positional"
      The status should be success
    End
    
    It "counts two positional parameters correctly"
      param_handler::simple_handle TWO_PARAMS "first_positional" "second_positional"
      When call param_handler::get_positional_count
      The output should equal "2"
    End
    
    It "handles two mixed parameters correctly"
      When call param_handler::simple_handle TWO_PARAMS --param1 "named_value" "positional_value"
      The variable FIRST_PARAM should equal "named_value"
      The variable SECOND_PARAM should equal "positional_value"
      The status should be success
    End
    
    It "counts named and positional parameters correctly in mixed two-parameter case"
      param_handler::simple_handle TWO_PARAMS --param1 "named_value" "positional_value"
      When call param_handler::get_named_count
      The output should equal "1"
      # Separate assertion for positional count
    End

    It "counts positional parameters correctly in mixed two-parameter case"
      param_handler::simple_handle TWO_PARAMS --param1 "named_value" "positional_value"
      When call param_handler::get_positional_count
      The output should equal "1"
    End
    
    # For the 8-parameter case, split into smaller tests to reduce complexity
    It "handles eight named parameters correctly"
      When call param_handler::simple_handle MANY_PARAMS --param1 "v1" --param2 "v2" --param3 "v3" --param4 "v4" --param5 "v5" --param6 "v6" --param7 "v7" --param8 "v8"
      The variable PARAM1 should equal "v1"
      The variable PARAM2 should equal "v2"
      The variable PARAM3 should equal "v3"
      The variable PARAM4 should equal "v4"
      The variable PARAM5 should equal "v5"
      The variable PARAM6 should equal "v6"
      The variable PARAM7 should equal "v7"
      The variable PARAM8 should equal "v8"
      The status should be success
    End
    
    It "counts eight named parameters correctly"
      param_handler::simple_handle MANY_PARAMS --param1 "v1" --param2 "v2" --param3 "v3" --param4 "v4" --param5 "v5" --param6 "v6" --param7 "v7" --param8 "v8"
      When call param_handler::get_named_count
      The output should equal "8"
    End
    
    It "handles eight positional parameters correctly (first four)"
      When call param_handler::simple_handle MANY_PARAMS "p1" "p2" "p3" "p4" "p5" "p6" "p7" "p8"
      The variable PARAM1 should equal "p1"
      The variable PARAM2 should equal "p2"
      The variable PARAM3 should equal "p3"
      The variable PARAM4 should equal "p4"
      The status should be success
    End
    
    It "handles eight positional parameters correctly (last four)"
      param_handler::simple_handle MANY_PARAMS "p1" "p2" "p3" "p4" "p5" "p6" "p7" "p8"
      The variable PARAM5 should equal "p5"
      The variable PARAM6 should equal "p6"
      The variable PARAM7 should equal "p7"
      The variable PARAM8 should equal "p8"
    End
    
    It "counts eight positional parameters correctly"
      param_handler::simple_handle MANY_PARAMS "p1" "p2" "p3" "p4" "p5" "p6" "p7" "p8"
      When call param_handler::get_positional_count
      The output should equal "8"
    End
    
    It "handles mixed eight parameters correctly (named odd, positional even)"
      When call param_handler::simple_handle MANY_PARAMS --param1 "v1" "p2" --param3 "v3" "p4" --param5 "v5" "p6" --param7 "v7" "p8"
      The variable PARAM1 should equal "v1"
      The variable PARAM2 should equal "p2"
      The variable PARAM3 should equal "v3"
      The variable PARAM4 should equal "p4"
      The status should be success
    End
    
    It "handles mixed eight parameters correctly (remaining vars)"
      param_handler::simple_handle MANY_PARAMS --param1 "v1" "p2" --param3 "v3" "p4" --param5 "v5" "p6" --param7 "v7" "p8"
      The variable PARAM5 should equal "v5"
      The variable PARAM6 should equal "p6"
      The variable PARAM7 should equal "v7"
      The variable PARAM8 should equal "p8"
    End
    
    It "counts parameters correctly in mixed eight parameter case"
      param_handler::simple_handle MANY_PARAMS --param1 "v1" "p2" --param3 "v3" "p4" --param5 "v5" "p6" --param7 "v7" "p8"
      When call param_handler::get_named_count
      The output should equal "4"
      # Separate assertion for positional count
    End

    It "counts positional parameters correctly in mixed eight parameter case"
      param_handler::simple_handle MANY_PARAMS --param1 "v1" "p2" --param3 "v3" "p4" --param5 "v5" "p6" --param7 "v7" "p8"
      When call param_handler::get_positional_count
      The output should equal "4"
    End
  End

  Context "checking parameter tracking"
    Describe "with named and positional parameters mixed"
      # Removed Before hook to avoid state pollution
      # Setup is now done within each It block
      
      It "tracks named parameter 'graphic' correctly"
        # Setup for this specific test
        param_handler::simple_handle STANDARD_PARAMS --virt-graphic "spice" "qxl" --gpu "nvidia"
        When call param_handler::was_set_by_name "graphic"
        The status should be success
      End
      
      It "detects video was not set by name"
        # Setup for this specific test
        param_handler::simple_handle STANDARD_PARAMS --virt-graphic "spice" "qxl" --gpu "nvidia"
        When call param_handler::was_set_by_name "video"
        The status should be failure
      End
      
      It "tracks named parameter 'gpu' correctly"
        # Setup for this specific test
        param_handler::simple_handle STANDARD_PARAMS --virt-graphic "spice" "qxl" --gpu "nvidia"
        When call param_handler::was_set_by_name "gpu"
        The status should be success
      End
      
      It "tracks positional parameter 'video' correctly"
        # Setup for this specific test
        param_handler::simple_handle STANDARD_PARAMS --virt-graphic "spice" "qxl" --gpu "nvidia"
        When call param_handler::was_set_by_position "video"
        The status should be success
      End
      
      It "detects graphic was not set by position"
        # Setup for this specific test
        param_handler::simple_handle STANDARD_PARAMS --virt-graphic "spice" "qxl" --gpu "nvidia"
        When call param_handler::was_set_by_position "graphic"
        The status should be failure
      End
      
      It "detects gpu was not set by position"
        # Setup for this specific test
        param_handler::simple_handle STANDARD_PARAMS --virt-graphic "spice" "qxl" --gpu "nvidia"
        When call param_handler::was_set_by_position "gpu"
        The status should be failure
      End
    End
  End
End 