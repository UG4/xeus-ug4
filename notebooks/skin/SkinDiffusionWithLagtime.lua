InitUG(2, AlgebraType("CPU", 1));
ug_load_script("ug_util.lua")
ug_load_script("util/refinement_util.lua")

requiredSubsets = {"LIP", "COR", "BOTTOM_SC", "TOP_SC"}
gridName = "skin2d-aniso.ugx"
numRefs = 2

dom = util.CreateDomain(gridName, numRefs, requiredSubsets)

approxSpaceDesc = { fct = "u", type = "Lagrange", order = 1 }

approxSpace = ApproximationSpace(dom)
approxSpace:add_fct(approxSpaceDesc.fct, approxSpaceDesc.type, approxSpaceDesc.order)
approxSpace:init_levels()
approxSpace:init_top_surface()
print("Approximation space:")
approxSpace:print_statistic()

K={
    ["LIP"] = 1.0, ["COR"] = 1.0,
}

D={
     ["LIP"] = 1, ["COR"] = 0.01, 
}


elemDisc ={}

elemDisc["COR"] = ConvectionDiffusion("u", "COR", "fv1")
elemDisc["COR"]:set_diffusion(K["COR"]*D["COR"])
elemDisc["COR"]:set_mass_scale(K["COR"])

elemDisc["LIP"] = ConvectionDiffusion("u", "LIP", "fv1")
elemDisc["LIP"]:set_diffusion(K["LIP"]*D["LIP"])
elemDisc["LIP"]:set_mass_scale(K["LIP"])

dirichletBnd = DirichletBoundary()
dirichletBnd:add(1.0, "u", "TOP_SC")
dirichletBnd:add(0.0, "u", "BOTTOM_SC")

domainDisc = DomainDiscretization(approxSpace)
domainDisc:add(elemDisc["LIP"])
domainDisc:add(elemDisc["COR"])
domainDisc:add(dirichletBnd)

A = AssembledLinearOperator(domainDisc)
u = GridFunction(approxSpace)
b = GridFunction(approxSpace)
u:set(0.0)


domainDisc:assemble_linear(A, b)
domainDisc:adjust_solution(u)

myLinearSolver =LU()
myLinearSolver:init(A, u)
myLinearSolver:apply(u, b)

area=Integral(1.0, u, "BOTTOM_SC")
print("Surface area [um^2]:")
print(area)

surfaceFlux = {}
surfaceFlux["BOT"] = K["LIP"]*D["LIP"]*IntegrateNormalGradientOnManifold(u, "u", "BOTTOM_SC", "LIP")
surfaceFlux["TOP"] = K["LIP"]*D["LIP"]*IntegrateNormalGradientOnManifold(u, "u", "TOP_SC", "LIP")
print("Surface fluxes [kg/s]:")
print(surfaceFlux["TOP"])
print(surfaceFlux["BOT"])

print("Normalized Fluxes [kg / (mu^2 * s)]:")
print(surfaceFlux["TOP"]/area)
print(surfaceFlux["BOT"]/area)

Jref = 0.05681818181818

print("Non Fluxes [kg / (mu^2 * s)]:")
print(surfaceFlux["TOP"]/(area*Jref))
print(surfaceFlux["BOT"]/(area*Jref))

-- auxiliary variables
-- for output 
out=VTKOutput()

-- for book-keeping
tOld = 0.0
jOld = 0.0
mOld = 0.0


function MyPostProcess(u, step, time)
  
  -- 1) Print solution to file.
  out:print("vtk/SkinDiffusionWithLagtime", u, step, time)
  
  -- 2) Compute fluxes.
  local gradFlux={}
  gradFlux["BOT"] = IntegrateNormalGradientOnManifold(u, "u", "BOTTOM_SC", "LIP")
  gradFlux["TOP"] = IntegrateNormalGradientOnManifold(u, "u", "TOP_SC", "LIP")
  
  local jTOP = K["LIP"]*D["LIP"]*gradFlux["TOP"]
  local jBOT = K["LIP"]*D["LIP"]*gradFlux["BOT"]
  print ("flux_top (\t"..time.."\t)=\t"..jTOP)
  print ("flux_bot (\t"..time.."\t)=\t"..jBOT)
  
  -- 3) Compute mass.
  local dt = time - tOld
  local mass = mOld + (time - tOld)*(jBOT + jOld)/2.0
  print ("mass_bot (\t"..time.."\t)=\t"..mass)
  
  -- 4) Compute lag time.
  print ("tlag=".. time - mass/jBOT )
  
  -- 5) Updates
  tOld = time
  jOld = jBOT
  mOld = mass

end

local solverDesc = {

    type = "newton",
    linSolver = myLinearSolver,
}

nlsolver = util.solver.CreateSolver(solverDesc)

u:set(0.0)

local startTime = 0.0
local endTime = 500.0
local dt=25.0
local dtMin=2.5
util.SolveNonlinearTimeProblem(u, domainDisc, nlsolver, MyPostProcess, "vtk/skin",
                            "ImplEuler", 1, startTime, endTime, dt, dtMin); 








