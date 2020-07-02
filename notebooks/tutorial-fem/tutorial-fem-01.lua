InitUG(2, AlgebraType("CPU", 1));  -- Initialize world dimension dim=2 and default algebra type
ug_load_script("ug_util.lua")           -- Load utility scripts (e.g. from from ugcore/scripts)
ug_load_script("util/refinement_util.lua")

myGridName= "grids/unit_square_quad.ugx" --"grids/unit_square_tri.ugx",
myNumRefs= 2
mySubsets = {"Inner", "Boundary"}

-- Callback fuer Randbedingungen
function myDirichletBndCallback(x, y, t)
    if (y==1) then 	return true, 0.0 
    elseif (y==0) then  return true, math.sin(math.pi*1*x)
    else return false, 0.0 
    end
end

dom = Domain()
LoadDomain(dom, myGridName)

print(util.CheckSubsets(dom, mySubsets))

local refiner = GlobalDomainRefiner(dom)
for i=1,myNumRefs do
    write(i .. " ")
    refiner:refine()
end

dom = util.CreateDomain(myGridName, myNumRefs, myRequiredSubsets)

-- Setup for FEM approximation space.
approxSpace = ApproximationSpace(dom)
approxSpace:add_fct("u", "Lagrange", 1)  -- Linear ansatz functions

-- More inits.
approxSpace:init_levels()
approxSpace:init_top_surface()
approxSpace:print_statistic()

elemDisc = ConvectionDiffusion("u", "Inner", "fe")
elemDisc:set_diffusion(1.0)

-- Optional: Setze rechte Seite f
-- elemDisc:set_source(1.0)

dirichletBND = DirichletBoundary()
dirichletBND:add("myDirichletBndCallback", "u", "Boundary")

domainDisc = DomainDiscretization(approxSpace)
domainDisc:add(elemDisc)
domainDisc:add(dirichletBND)

-- set up solver (using 'util/solver_util.lua')
local solverDesc = {
    type = "bicgstab",
    precond = {
        type = "gmg",
        approxSpace = approxSpace,
        smoother = "sgs",
        baseSolver = "lu"
    }
}
solver = util.solver.CreateSolver(solverDesc)

A = AssembledLinearOperator(domainDisc)
x = GridFunction(approxSpace)
b = GridFunction(approxSpace)
x:set(0.0)


domainDisc:assemble_linear(A, b)
domainDisc:adjust_solution(x)

solver:init(A, x)
solver:apply(x, b)

local solFileName = "x_solution"
WriteGridFunctionToVTK(x, solFileName)
SaveVectorForConnectionViewer(x, solFileName .. ".vec")

local matFileName = "A_matrix.mat"
SaveMatrixForConnectionViewer(x, A, matFileName)

local rhsFileName = "b_rhs"
SaveVectorForConnectionViewer(b, rhsFileName.. ".vec")












