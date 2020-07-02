InitUG(2, AlgebraType("CPU", 1));
ug_load_script("ug_util.lua")
ug_load_script("util/refinement_util.lua")

requiredSubsets = {"LIP", "COR", "BOTTOM_SC", "TOP_SC"}
gridName = "skin2d-aniso.ugx"
numRefs = 2

dom = util.CreateDomain(gridName, numRefs, requiredSubsets)

approxSpaceDesc = { fct = "c", type = "Lagrange", order = 1 }

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

elemDisc["COR"] = ConvectionDiffusion("c", "COR", "fv1")
elemDisc["COR"]:set_diffusion(K["COR"]*D["COR"])
elemDisc["COR"]:set_mass_scale(K["COR"])

elemDisc["LIP"] = ConvectionDiffusion("c", "LIP", "fv1")
elemDisc["LIP"]:set_diffusion(K["LIP"]*D["LIP"])
elemDisc["LIP"]:set_mass_scale(K["LIP"])

dirichletBnd = DirichletBoundary()
dirichletBnd:add(1.0, "c", "TOP_SC")
dirichletBnd:add(0.0, "c", "BOTTOM_SC")

domainDisc = DomainDiscretization(approxSpace)
domainDisc:add(elemDisc["LIP"])
domainDisc:add(elemDisc["COR"])
domainDisc:add(dirichletBnd)

solver=LU()

u = GridFunction(approxSpace)
u:set(0.0)

local startTime = 0.0
local endTime = 100.0
local dt=0.25
util.SolveLinearTimeProblem(u, domainDisc, solver, VTKOutput(), "vtk/skin",
                            "ImplEuler", 1, startTime, endTime, dt); 








