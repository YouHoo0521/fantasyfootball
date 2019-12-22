using JuMP, Cbc

function create_dk_position_indices(position)
    index = Dict()
    index["qb"] = [i for (i, j) in enumerate(position) if j == "QB"];
    index["rb"] = [i for (i, j) in enumerate(position) if j == "RB"];
    index["wr"] = [i for (i, j) in enumerate(position) if j == "WR"];
    index["te"] = [i for (i, j) in enumerate(position) if j == "TE"];
    index["dst"] = [i for (i, j) in enumerate(position) if j == "DST"];
    index["flex"] = [index["rb"]; index["wr"]; index["te"]];
    index;
end

function solve_deterministic(data)
    N = size(data)[1]  # num players
    points = data[!, :FantasyPointsDraftKings];
    salary = data[:, :DraftKingsSalary];
    position = data[:, :Position];

    position_index = create_dk_position_indices(position)

    m = Model(with_optimizer(Cbc.Optimizer, logLevel=0))
    @variable(m, x[1:N], Bin)
    @objective(m, Max, points' * x)
    @constraint(m, salary' * x <= 50000)
    @constraint(m, sum(x[i] for i = position_index["qb"]) == 1)
    @constraint(m, 2 <= sum(x[i] for i = position_index["rb"]) <= 3)
    @constraint(m, 3 <= sum(x[i] for i = position_index["wr"]) <= 4)
    @constraint(m, 1 <= sum(x[i] for i = position_index["te"]) <= 2)
    @constraint(m, sum(x[i] for i = position_index["flex"]) == 7)
    @constraint(m, sum(x[i] for i = position_index["dst"]) == 1)
    @constraint(m, sum(x) == 9);

    optimize!(m)
    print("$(termination_status(m))\n")
    solution = data[value.(x) .>= 0.9, [:Name, :Team, :Position, :DraftKingsSalary, :FantasyPointsDraftKings]]
    display(solution);
    print("Total salary: $(sum(solution[!, :DraftKingsSalary]))\n")
    print("Total points: $(sum(solution[!, :FantasyPointsDraftKings]))\n")

    solution;
end
