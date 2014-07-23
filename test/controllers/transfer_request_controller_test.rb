# -*- encoding : utf-8 -*-
require 'test_helper'

class TransferRequestControllerTest < ActionController::TestCase
  test "create should reject if request_user_id is not supplied" do
    post :create, target_user_id: 1, offered_player_id: 2, target_player_id: 3
    assert_response :unprocessable_entity
  end

  test "create should reject if target_user_id is not supplied" do
    post :create, request_user_id: 1, offered_player_id: 2, target_player_id: 3
    assert_response :unprocessable_entity
  end

  test "create should reject if offered_player_id is not supplied" do
    post :create, request_user_id: 1, target_user_id: 2, target_player_id: 3
    assert_response :unprocessable_entity
  end

  test "create should reject if target_player_id is not supplied" do
    post :create, request_user_id: 1, target_user_id: 2, offered_player_id: 3
    assert_response :unprocessable_entity
  end

  test "create should reject if request_user_id is invalid" do
    post :create, request_user_id: -2, target_user_id: 2, offered_player_id: 3, target_player_id: 4
    assert_response :not_found
  end

  test "create should reject if target_user_id can't be found" do
    post :create, request_user_id: 1, target_user_id: 50_000, offered_player_id: 3, target_player_id: 4
    assert_response :not_found
  end

  test "create should reject if offered_player_id is invalid" do
    post :create, request_user_id: 1, target_user_id: 2, offered_player_id: "a string", target_player_id: 4
    assert_response :not_found
  end

  test "create should reject if target_player_id can't be found" do
    post :create, request_user_id: 1, target_user_id: 2, offered_player_id: 3, target_player_id: 50_000
    assert_response :not_found
  end

  test "if all are valid then a transfer request is created" do
    post :create, request_user_id: 1, target_user_id: 2, offered_player_id: 3, target_player_id: 4
    assert_response :success

    transfer_request = TransferRequest.last
    assert_equal 1, transfer_request.request_user.id
    assert_equal 2, transfer_request.target_user.id
    assert_equal 3, transfer_request.offered_player.id
    assert_equal 4, transfer_request.target_player.id
  end

  test "resolve should reject if action_typ isn't specified" do
    post :resolve, id: 1
    assert_response :unprocessable_entity
  end

  test "resolve should reject if action_typ is invalid" do
    post :resolve, id: 1, action_type: "shpoople"
    assert_response :unprocessable_entity
  end

  test "resolve should reject if id is wrong" do
    post :resolve, id: 50_000, action_type: "accept"
    assert_response :not_found
  end

  test "nothing changes if it's rejected" do
    post :resolve, id: 2, action_type: "reject"
    assert_response :success

    game_week_team_player_one = GameWeekTeamPlayer.find(55)
    game_week_team_player_two = GameWeekTeamPlayer.find(56)

    assert_equal 3, game_week_team_player_one.game_week_team.user.id
    assert_equal 4, game_week_team_player_two.game_week_team.user.id
  end

  test "users are swapped if it's accepted" do
    post :resolve, id: 2, action_type: "accept"
    assert_response :success

    game_week_team_player_one = GameWeekTeamPlayer.find(55)
    game_week_team_player_two = GameWeekTeamPlayer.find(56)

    assert_equal 4, game_week_team_player_one.game_week_team.user.id
    assert_equal 3, game_week_team_player_two.game_week_team.user.id
  end

  test "transfer request is deleted after accept" do
    post :resolve, id: 2, action_type: "accept"
    assert_response :success

    assert_raise ActiveRecord::RecordNotFound do
      TransferRequest.find(2)
    end
  end

  test "transfer request is deleted after reject" do
    post :resolve, id: 2, action_type: "reject"
    assert_response :success

    assert_raise ActiveRecord::RecordNotFound do
      TransferRequest.find(2)
    end
  end

  # Test that playing / not playing is switched between players
  # Check any other potential trades are cancelled
end
