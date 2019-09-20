@FEATURE_ROLLOUT
Feature: GetFeatureVariable API - Audience Targeting in Feature Rollouts

  Background:
    Given the datafile is "feature_rollouts.json"
    And 1 "Activate" listener is added

  @ALL
  Scenario Outline: User is in rollout
    Test that when the user is bucketed into the rollout, then the SDK returns
    the variable value overrides.

    When get_feature_variable_integer is called with arguments
      """
        feature_flag_key: <feature_key>
        variable_key: i_42
        user_id: test_user_1
        attributes:
          s_foo: <s_foo>
      """
    Then the result should be 43
    When get_feature_variable_double is called with arguments
      """
        feature_flag_key: <feature_key>
        variable_key: d_4_2
        user_id: test_user_1
        attributes:
          s_foo: <s_foo>
      """
    Then the result should be 4.3
    When get_feature_variable_boolean is called with arguments
      """
        feature_flag_key: <feature_key>
        variable_key: b_true
        user_id: test_user_1
        attributes:
          s_foo: <s_foo>
      """
    Then the result should be boolean "FALSE"
    When get_feature_variable_string is called with arguments
      """
        feature_flag_key: <feature_key>
        variable_key: s_foo
        user_id: test_user_1
        attributes:
          s_foo: <s_foo>
      """
    Then the result should be "bar"
    And in the response, "listener_called" should be "NULL"
    And there are no dispatched events

  Examples:
    | feature_key                    | s_foo           |
    | feature_rollout_100_targeted   | foo             |
    | feature_rollout_100_untargeted | does_not_matter |

  @GET_FEATURE_VAR
  Scenario Outline: User is in rollout, non-typed
    Test that when the user is bucketed into the rollout, then the SDK returns
    the variable value overrides.

    When get_feature_variable is called with arguments
      """
        feature_flag_key: feature_rollout_100_targeted
        variable_key: <variable_key>
        user_id: test_user_1
        attributes:
          s_foo: foo
      """
    Then the result should be <type> <result>
    And in the response, "listener_called" should be "NULL"
    And there are no dispatched events
    When get_feature_variable is called with arguments
      """
        feature_flag_key: feature_rollout_100_untargeted
        variable_key: <variable_key>
        user_id: test_user_1
        attributes:
          s_foo: does_not_matter
      """
    Then the result should be <type> <result>
    And in the response, "listener_called" should be "NULL"
    And there are no dispatched events

  Examples:
    | variable_key | type    | result  |
    | i_42         | integer | 43      |
    | d_4_2        | double  | 4.3     |
    | b_true       | boolean | "FALSE" |
    | s_foo        | string  | "bar"   |

  @ALL
  Scenario Outline: User is not in rollout
    Test that when the user is not bucketed into the rollout, then the SDK returns
    the variable default values.

    When get_feature_variable_integer is called with arguments
      """
        feature_flag_key: <feature_key>
        variable_key: i_42
        user_id: test_user_1
        attributes:
          s_foo: <s_foo>
      """
    Then the result should be 42
    When get_feature_variable_double is called with arguments
      """
        feature_flag_key: <feature_key>
        variable_key: d_4_2
        user_id: test_user_1
        attributes:
          s_foo: <s_foo>
      """
    Then the result should be 4.2
    When get_feature_variable_boolean is called with arguments
      """
        feature_flag_key: <feature_key>
        variable_key: b_true
        user_id: test_user_1
        attributes:
          s_foo: <s_foo>
      """
    Then the result should be boolean "TRUE"
    When get_feature_variable_string is called with arguments
      """
        feature_flag_key: <feature_key>
        variable_key: s_foo
        user_id: test_user_1
        attributes:
          s_foo: <s_foo>
      """
    Then the result should be "foo"
    And in the response, "listener_called" should be "NULL"
    And there are no dispatched events

  Examples:
    | feature_key                  | s_foo           |
    | feature_rollout_0_targeted   | not_foo         |
    | feature_rollout_0_untargeted | does_not_matter |

  @GET_FEATURE_VAR
  Scenario Outline: User is not in rollout
    Test that when the user is not bucketed into the rollout, then the SDK returns
    the variable default values.

    When get_feature_variable is called with arguments
      """
        feature_flag_key: feature_rollout_0_targeted
        variable_key: <variable_key>
        user_id: test_user_1
        attributes:
          s_foo: not_foo
      """
    Then the result should be <type> <result>
    And in the response, "listener_called" should be "NULL"
    And there are no dispatched events
    When get_feature_variable is called with arguments
      """
        feature_flag_key: feature_rollout_0_untargeted
        variable_key: <variable_key>
        user_id: test_user_1
        attributes:
          s_foo: does_not_matter
      """
    Then the result should be <type> <result>
    And in the response, "listener_called" should be "NULL"
    And there are no dispatched events

  Examples:
    | variable_key | type    | result |
    | i_42         | integer | 42     |
    | d_4_2        | double  | 4.2    |
    | b_true       | boolean | "TRUE" |
    | s_foo        | string  | "foo"  |
