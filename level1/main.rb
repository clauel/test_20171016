require "json"


class PlanningDeGarde
  def initialize(dataFile, outputFile)
    @data = JSON.parse(File.read(dataFile))
    @output = outputFile
  end

  def perform
    schedule = {}
    schedule["workers"] = get_schedule
    File.open(@output,"w") do |f|
      f.write(schedule.to_json)
    end
  end

  private
    def get_schedule
      @data["shifts"].
      group_by {|shift| shift["user_id"]}.
      map do |user_id, shifts|
        {
          "id" => user_id,
          "price" => select_user(user_id)["price_per_shift"]*shifts.count
        }
      end
    end

    def select_user(user_id)
      @data["workers"].select{|worker| worker["id"] == user_id}[0]
    end

end

PlanningDeGarde.new('data.json', 'output.json').perform
