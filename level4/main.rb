require 'json'
require 'date'


class PlanningDeGarde
  MED_PAY = {"medic" => 270 , "interne" => 126, "interim" => 480}

  def initialize(dataFile, outputFile)
    @data = JSON.parse(File.read(dataFile))
    @output = outputFile
    @result = result_initialized
  end

  def perform
    loop(@data["shifts"])
    File.open(@output,"w") do |f|
      f.write(@result.to_json)
    end
  end

  private

#First we initialize with 0 values the output Hash
    def result_initialized
      workers =[]
      @data["workers"].size.times do |worker|
        workers.push ({
          "id" => @data["workers"][worker]["id"],
          "price" => 0
        })
      end
      {
        "workers" => workers,
        "commission" => {
                          "pdg_fee": 0,
                          "interim_shifts": 0
                        }
      }
    end

    def loop(shifts)
      addShiftToResult(shifts[0])
      loop(shifts[1..-1]) if shifts.length > 1
    end

    def addShiftToResult(shift)
      #if the user_id is not assigned to a worker, we skip the shift
      unless shift["user_id"] == nil
        shift_details = details(shift) #returns a hash with user status and price of the shift
        select_user(shift["user_id"],@result)["price"] += shift_details["price"]
        @result["commission"][:pdg_fee] += shift_details["price"] * 0.05
        if shift_details["status"] == "interim"
          @result["commission"][:interim_shifts] += 1
          @result["commission"][:pdg_fee] += 80
        end
      end
    end

    def details(shift)
      start_date_weekday = Date.parse(shift["start_date"]).wday
      count = (start_date_weekday == 0) || (start_date_weekday == 6) ? 2 : 1
      status = select_user(shift["user_id"],@data)["status"]
      {
        "status" => status,
        "price" => count * MED_PAY[status]
      }
    end

    def select_user(user_id, hash)
      hash["workers"].select{|worker| worker["id"] == user_id}[0]
    end

end

PlanningDeGarde.new('data.json', 'output.json').perform
