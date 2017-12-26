module UsersHelper
  def segment_of_day
    hour = Time.now.hour

    if hour < 12
      return 'morning'
    elsif hour >= 12 && hour <=19
      return 'afternoon'
    else
      return 'evening'
    end
  end
end
