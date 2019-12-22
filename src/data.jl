using CSV, DataFrames

function get_basedir(year, project_relpath="..")
    "$(project_relpath)/data/raw/$(year)/"
end

function load_salary(year, week, project_relpath="..")
    base_dir = get_basedir(year, project_relpath)
    salary_path = base_dir * "salary_dk_w$(week).csv"
    salary = DataFrame(CSV.read(salary_path));
    salary = salary[salary[!, :DraftKingsSalary] .!= "null", :];
    salary[!, :DraftKingsSalary] = parse.(Int, salary[!,:DraftKingsSalary]);
    salary = salary[:, [:Name, :Team, :Position, :Opponent, :DraftKingsSalary]]
end

function load_weekly_data(year, max_week, min_week=1, project_relpath="..", future=false)
    data = DataFrame()
    for week in min_week:max_week
        base_dir = get_basedir(year, project_relpath)
        points_path = base_dir * "points_dk_w$(week).csv"
        salary_path = base_dir * "salary_dk_w$(week).csv"
        allowed_path = base_dir * "allowed_dk_w$(week).csv"
        points = DataFrame(CSV.read(points_path));
        # get salary at the time of game
        salary = load_salary(year, week, project_relpath)
        # get points allowed
        allowed = DataFrame(CSV.read(allowed_path));
        allowed[!, :Team] = allowed[!, :Opponent];
        allowed = select!(allowed, Not([:Rank, :Name, :Position, :Week, :Opponent]))

        # join salary data
        weekly_data = join(salary, points,
                           on = [:Name, :Team, :Position, :Opponent],
                           kind = :inner)

        # join allowed data
        weekly_data = join(weekly_data, allowed,
                           on = :Team,
                           kind = :left)

        # append weekly data to output
        data = [data; weekly_data];
    end

    # convert FB to RB
    position = data[!, :Position]
    position[position .== "FB"] .= "RB"

    select!(data, Not([:FantasyPointsPerGameDraftKings,
                             :Rank]));
end

function load_validation_data(year, cur_week)
    cur_salary = load_salary(year, cur_week)
    validation_data = load_weekly_data(year, cur_week, cur_week)
    validation_data = join(cur_salary,
                           validation_data[:, [:Name, :Team, :FantasyPointsDraftKings]],
                           on = [:Name, :Team],
                           kind = :left
                           )
    validation_data[!, :FantasyPointsDraftKings] = coalesce.(validation_data[:, :FantasyPointsDraftKings], 0.0);
    validation_data
end


function main()
    year = 2018
    cur_week = 16
    project_relpath=".."

    past_data = load_weekly_data(year, cur_week-1)
    cur_salary = load_salary(year, cur_week)
    vd = load_validation_data(year, cur_week)
end
