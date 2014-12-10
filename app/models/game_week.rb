# -*- encoding : utf-8 -*-
class GameWeek < ActiveRecord::Base
  include WithGameWeek

  HOURS_UNTIL_5_PM = 17

  # Game week starts on a tuesday (after MNF)
  DAYS_IN_WEEK_BEFORE_LOCK = 2

  def self.find_unique_with(game_week)
    WithGameWeek.validate_game_week_number(game_week)

    gw_obj_list = GameWeek.where(number: game_week)

    # There should only we one of these
    no_of_gw_objs = gw_obj_list.size
    if no_of_gw_objs == 0
      fail ActiveRecord::RecordNotFound, "Didn't find a record with game week '#{game_week}'"
    elsif no_of_gw_objs > 1
      fail IllegalStateError, "Found #{no_of_gw_objs} game weeks with game week '#{game_week}'"
    end

    # Return what must be the only element
    gw_obj_list.first
  end

  has_many :match_players
  has_many :game_week_teams

  validates :number,
            presence: true,
            uniqueness: true

  validate :number_is_in_correct_range

  def number_is_in_correct_range
    return unless number.present?
    WithGameWeek.validate_game_week_number(number)
  rescue ArgumentError
    errors.add(:number, 'is not between 1 and #{Settings.number_of_gameweeks} inclusive')
  end

  def active?
    days_for_game_week_start = (number - 1) * WithGameWeek::DAYS_IN_A_WEEK
    days_for_game_week_end = number * WithGameWeek::DAYS_IN_A_WEEK

    is_after_game_week_start = WithGameWeek.more_than_days_since_start?(days_for_game_week_start)
    is_after_game_week_end = WithGameWeek.more_than_days_since_start?(days_for_game_week_end)

    is_after_game_week_start && !is_after_game_week_end
  end
  
   def locked?
    days_for_game_week_start = (number - 1) * WithGameWeek::DAYS_IN_A_WEEK
    days_until_thursday = days_for_game_week_start + 2

    WithGameWeek.more_than_time_since_start?(days_until_thursday, HOURS_UNTIL_5_PM)
  end

end
