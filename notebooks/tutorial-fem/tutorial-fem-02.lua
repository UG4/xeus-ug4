InitUG(2, AlgebraType("CPU", 1));  -- Initialize world dimension dim=2 and default algebra type
ug_load_script("ug_util.lua")           -- Load utility scripts (e.g. from from ugcore/scripts)
ug_load_script("util/refinement_util.lua")

SQUARE_CONFIG =
{
    -- Geometrie
    gridName= "grids/unit_square_quad.ugx", --"grids/unit_square_tri.ugx",
    requiredSubsets = {"Inner", "Boundary"},
    numRefs= 1,
    
    -- Randbedingungen
    dirichletData = 
    {
        subsets = "Boundary", callback = "MyDirichletBndCallback",  
    },
    
    -- Parameter fuer PDE    
    diffusion = 1.0,  -- D=1.0
    source = 0.0,   -- f=0
}

-- Callback fuer Randbedingungen
function MyDirichletBndCallback(x, y, t)
    if (y==1) then 	return true, 0.0 
    elseif (y==0) then  return true, math.sin(math.pi*1*x)
    else return false, 0.0 
    end
end


CONFIG=SQUARE_CONFIG

SQUARE_CONFIG2 =
{
    -- Geometrie
    gridName= "grids/unit_square_quad.ugx",
    requiredSubsets = {"Inner", "Boundary"},
    numRefs= 3,
    
    -- Randbedingungen
    dirichletData = 
    {
        subsets = "Boundary", callback = "MyDirichletBndCallback",  
    },
    
    diffusion = 1.0,
    source = "MySourceCallback", 
    myref = "MyRefCallback",
}

-- Callback fuer Randbedingungen
function MyDirichletBndCallback(x, y, t)
    if (y==1) then 	return true, 0.0 
    elseif (y==0) then  return true, math.sin(math.pi*1*x)
    else return false, 0.0 
    end
end

-- Callback fuer Randbedingungen
function MyDirichletBndCallback(x, y, t)
     return true, 0.0 
end

-- Callback fuer rechte Seite
function MySourceCallback(x, y, t)
    local mu = 1.0
    local nu = 4.0
    local scale =  (mu*mu + nu*nu)*(math.pi)*(math.pi)
    return scale*math.sin(math.pi*mu*x)* math.sin(math.pi*nu*y)
end


-- Callback fuer Referenz
function MyRefCallback(x, y, t)
    local mu = 1.0
    local nu = 4.0
    return math.sin(math.pi*mu*x)* math.sin(math.pi*nu*y)
end

-- CONFIG=SQUARE_CONFIG2

SECTOR_CONFIG =
{
    gridName= "grids/sector_ref0.ugx",
    requiredSubsets = {"Inner", "circle", "cut"},
    numRefs= 3,
    
    dirichletData = 
    {
        subsets = "circle, cut", callback = "SectorDirichletSol",  
    },
    
    diffusion = 1.0,
    source = 0.0, 
    myref = "SectorDirichletSol"
}

-- callback function boundary values (only the ones matching 'dim' are used)
function SectorDirichletSol(x, y, t, si)
    local r = math.sqrt(x*x+y*y);
    local phi = math.atan2(y,x);
    if (phi<0) then phi = phi + 2*math.pi; end
    val=math.pow(r,(2/3))*math.sin(phi/3.0*2);
    return val
end
-- CONFIG = SECTOR_CONFIG


dom = Domain()
LoadDomain(dom, CONFIG.gridName)

print(util.CheckSubsets(dom, CONFIG.requiredSubsets))

local refiner = GlobalDomainRefiner(dom)
for i=1,CONFIG.numRefs do
    write(i .. " ")
    refiner:refine()
end

dom = util.CreateDomain(CONFIG.gridName, CONFIG.numRefs, CONFIG.requiredSubsets)

-- Setup for FEM approximation space.
approxSpace = ApproximationSpace(dom)
approxSpace:add_fct("c", "Lagrange", 1)  -- Linear ansatz functions

-- More inits.
approxSpace:init_levels()
approxSpace:init_top_surface()
approxSpace:print_statistic()

elemDisc = ConvectionDiffusion("c", "Inner", "fe")
elemDisc:set_diffusion(CONFIG.diffusion)

if (CONFIG.source) then
    elemDisc:set_source(CONFIG.source)
end

dirichletBND = DirichletBoundary()
dirichletBND:add(CONFIG.dirichletData.callback, "c", CONFIG.dirichletData.subsets)

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
u = GridFunction(approxSpace)
b = GridFunction(approxSpace)
u:set(0.0)


domainDisc:assemble_linear(A, b)
domainDisc:adjust_solution(u)

solver:init(A, u)
solver:apply(u, b)

local solFileName = "u_solution"
WriteGridFunctionToVTK(u, solFileName)
SaveVectorForConnectionViewer(u, solFileName .. ".vec")

if (CONFIG.myref) then
    err0=L2Error(CONFIG.myref,  u, "c", 1.0, 4)
    print(err0)
end

if (CONFIG.myref) then
    uref = u:clone()
    Interpolate(CONFIG.myref, uref, "c")
    err1=H1Error(uref, "c",  u, "c", 1.0, "Inner")
    print(err1)
end

--[[ Append to file
local file = io.open("results.txt", "w") -- opens a file in append mode
io.output(file) -- 
io.write(err0.."\t"..err1)
io.close(file)
--]] 

local matFileName = "A_matrix.mat"
print("writing stiffness matrix to " .. matFileName)
SaveMatrixForConnectionViewer(u, A, matFileName)

local rhsFileName = "b_rhs"
print("writing rhs to '" .. rhsFileName .. ".*'")
SaveVectorForConnectionViewer(b, rhsFileName.. ".vec")

os.execute('gnuplot < test.gnuplot ')
print("done")








