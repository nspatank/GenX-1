"""
GenX: An Configurable Capacity Expansion Model
Copyright (C) 2021,  Massachusetts Institute of Technology
This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
A complete copy of the GNU General Public License v2 (GPLv2) is available
in LICENSE.txt.  Users uncompressing this from an archive may not have
received this license file.  If not, see <http://www.gnu.org/licenses/>.
"""

@doc raw"""
	storage(EP::Model, inputs::Dict, Reserves::Int, OperationWrapping::Int, LongDurationStorage::Int, EnergyShareRequirement::Int, CapacityReserveMargin::Int)
A wide range of energy storage devices (all $o \in \mathcal{O}$) can be modeled in GenX, using one of two generic storage formulations: (1) storage technologies with symmetric charge and discharge capacity (all $o \in \mathcal{O}^{sym}$), such as Lithium-ion batteries and most other electrochemical storage devices that use the same components for both charge and discharge; and (2) storage technologies that employ distinct and potentially asymmetric charge and discharge capacities (all $o \in \mathcal{O}^{asym}$), such as most thermal storage technologies or hydrogen electrolysis/storage/fuel cell or combustion turbine systems.
**Storage with symmetric charge and discharge capacity**
For storage technologies with symmetric charge and discharge capacity (all $o \in \mathcal{O}^{sym}$), charge rate, $\Pi_{o,z,t}$, is constrained by the total installed power capacity, $\Omega_{o,z}$. Since storage resources generally represent a `cluster' of multiple similar storage devices of the same type/cost in the same zone, GenX permits storage resources to simultaneously charge and discharge (as some units could be charging while others discharge), with the simultaenous sum of charge, $\Pi_{o,z,t}$, and discharge, $\Theta_{o,z,t}$, also limited by the total installed power capacity, $\Delta^{total}_{o,z}$. These two constraints are as follows:
```math
\begin{aligned}
	&  \Pi_{o,z,t} \leq \Delta^{total}_{o,z} & \quad \forall o \in \mathcal{O}^{sym}, z \in \mathcal{Z}, t \in \mathcal{T}\\
	&  \Pi_{o,z,t} + \Theta_{o,z,t} \leq \Delta^{total}_{o,z} & \quad \forall o \in \mathcal{O}^{sym}, z \in \mathcal{Z}, t \in \mathcal{T}
\end{aligned}
```
These constraints are created with the function ```storage_symmetric()``` in ```storage_symmetric.jl```.
If reserves are modeled, the following two constraints replace those above:
```math
\begin{aligned}
&  \Pi_{o,z,t} + f^{charge}_{o,z,t} \leq \Delta^{total}_{o,z} & \quad \forall o \in \mathcal{O}^{sym}, z \in \mathcal{Z}, t \in \mathcal{T}\\
&  \Pi_{o,z,t} + f^{charge}_{o,z,t} + \Theta_{o,z,t} + f^{discharge}_{o,z,t} + r^{discharge}_{o,z,t} \leq \Delta^{total}_{o,z} & \quad \forall o \in \mathcal{O}^{sym}, z \in \mathcal{Z}, t \in \mathcal{T} \\
\end{aligned}
```
where $f^{charge}_{o,z,t}$ is the contribution of storage resources to frequency regulation while charging, $f^{discharge}_{o,z,t}$ is the contribution of storage resources to frequency regulation while discharging, and $r^{discharge}_{o,z,t}$ is the contribution of storage resources to upward reserves while discharging. Note that as storage resources can contribute to regulation and reserves while either charging or discharging, the proxy variables $f^{charge}_{o,z,t}, f^{discharge}_{o,z,t}$ and $r^{charge}_{o,z,t}, r^{discharge}_{o,z,t}$ are created for storage resources where the total contribution to regulation and reserves, $f_{o,z,t}, r_{o,z,t}$ is the sum of the proxy variables.
These constraints are created with the function ```storage_symmetric_reserves()``` in ```storage_symmetric.jl```.
**Storage with asymmetric charge and discharge capacity**
For storage technologies with asymmetric charge and discharge capacities (all $o \in \mathcal{O}^{asym}$), charge rate, $\Pi_{o,z,t}$, is constrained by the total installed charge capacity, $\Delta^{total, charge}_{o,z}$, as follows:
```math
\begin{aligned}
	&  \Pi_{o,z,t} \leq \Delta^{total, charge}_{o,z} & \quad \forall o \in \mathcal{O}^{asym}, z \in \mathcal{Z}, t \in \mathcal{T}
\end{aligned}
```
These constraints are created with the function ```storage_asymmetric()``` in ```storage_asymmetric.jl```.
If reserves are modeled, the above constraint is replaced by the following:
```math
\begin{aligned}
	&  \Pi_{o,z,t} + f^{charge}_{o,z,t} \leq \Delta^{total, charge}_{o,z} & \quad \forall o \in \mathcal{O}^{asym}, z \in \mathcal{Z}, t \in \mathcal{T}
\end{aligned}
```
where $f^{+}_{y=o,z,t}$ is the contribution of storage resources to frequency regulation while charging.
These constraints are created with the function ```storage_asymmetric_reserves()``` in ```storage_asymmetric.jl```.
**All storage resources**
The following constraints apply to all storage resources, $o \in \mathcal{O}$, regardless of whether the charge/discharge capacities are symmetric or asymmetric.
The following two constraints track the state of charge of the storage resources at the end of each time period, relating the volume of energy stored at the end of the time period, $\Gamma_{o,z,t}$, to the state of charge at the end of the prior time period, $\Gamma_{o,z,t-1}$, the charge and discharge decisions in the current time period, $\Pi_{o,z,t}, \Theta_{o,z,t}$, and the self discharge rate for the storage resource (if any), $\eta_{o,z}^{loss}$.  The first of these two constraints enforces storage inventory balance for interior time steps $(t \in \mathcal{T}^{interior})$, while the second enforces storage balance constraint for the initial time step $(t \in \mathcal{T}^{start})$.
```math
\begin{aligned}
	&  \Gamma_{o,z,t} =\Gamma_{o,z,t-1} - \frac{1}{\eta_{o,z}^{discharge}}\Theta_{o,z,t} + \eta_{o,z}^{charge}\Pi_{o,z,t} - \eta_{o,z}^{loss}\Gamma_{o,z,t-1}  \quad \forall o \in \mathcal{O}, z \in \mathcal{Z}, t \in \mathcal{T}^{interior}\\
	&  \Gamma_{o,z,t} =\Gamma_{o,z,t+\tau^{period}-1} - \frac{1}{\eta_{o,z}^{discharge}}\Theta_{o,z,t} + \eta_{o,z}^{charge}\Pi_{o,z,t} - \eta_{o,z}^{loss}\Gamma_{o,z,t+\tau^{period}-1}  \quad \forall o \in \mathcal{O}, z \in \mathcal{Z}, t \in \mathcal{T}^{start}
\end{aligned}
```
When modeling the entire year as a single chronological period with total number of time steps of $\tau^{period}$, storage inventory in the first time step is linked to storage inventory at the last time step of the period representing the year. Alternatively, when modeling the entire year with multiple representative periods, this constraint relates storage inventory in the first timestep of the representative period with the inventory at the last time step of the representative period, where each representative period is made of $\tau^{period}$ time steps. In this implementation, energy exchange between representative periods is not permitted. When modeling representative time periods, GenX enables modeling of long duration energy storage which tracks state of charge between representative periods enable energy to be moved throughout the year. If ```LongDurationStorage=1``` and ```OperationWrapping=1```, this function calls ```long_duration_storage()``` in ```long_duration_storage.jl``` to enable this feature.
The next constraint limits the volume of energy stored at any time, $\Gamma_{o,z,t}$, to be less than the installed energy storage capacity, $\Delta^{total, energy}_{o,z}$. Finally, the maximum discharge rate for storage resources, $\Pi_{o,z,t}$, is constrained to be less than the discharge power capacity, $\Omega_{o,z,t}$ or the state of charge at the end of the last period, $\Gamma_{o,z,t-1}$, whichever is lessor.
```math
\begin{aligned}
	&  \Gamma_{o,z,t} \leq \Delta^{total, energy}_{o,z} & \quad \forall o \in \mathcal{O}, z \in \mathcal{Z}, t \in \mathcal{T}\\
	&  \Theta_{o,z,t} \leq \Delta^{total}_{o,z} & \quad \forall o \in \mathcal{O}, z \in \mathcal{Z}, t \in \mathcal{T}\\
	&  \Theta_{o,z,t} \leq \Gamma_{o,z,t-1} & \quad \forall o \in \mathcal{O}, z \in \mathcal{Z}, t \in \mathcal{T}
\end{aligned}
```
The above constraints are established in ```storage_all()``` in ```storage_all.jl```.
If reserves are modeled, two pairs of proxy variables $f^{charge}_{o,z,t}, f^{discharge}_{o,z,t}$ and $r^{charge}_{o,z,t}, r^{discharge}_{o,z,t}$ are created for storage resources, to denote the contribution of storage resources to regulation or reserves while charging or discharging, respectively. The total contribution to regulation and reserves, $f_{o,z,t}, r_{o,z,t}$ is then the sum of the proxy variables:
```math
\begin{aligned}
	&  f_{o,z,t} = f^{charge}_{o,z,t} + f^{dicharge}_{o,z,t} & \quad \forall o \in \mathcal{O}, z \in \mathcal{Z}, t \in \mathcal{T}\\
	&  r_{o,z,t} = r^{charge}_{o,z,t} + r^{dicharge}_{o,z,t} & \quad \forall o \in \mathcal{O}, z \in \mathcal{Z}, t \in \mathcal{T}
\end{aligned}
```
The total storage contribution to frequency regulation ($f_{o,z,t}$) and reserves ($r_{o,z,t}$) are each limited specified fraction of installed discharge power capacity ($\upsilon^{reg}_{y,z}, \upsilon^{rsv}_{y,z}$), reflecting the maximum ramp rate for the storage resource in whatever time interval defines the requisite response time for the regulation or reserve products (e.g., 5 mins or 15 mins or 30 mins). These response times differ by system operator and reserve product, and so the user should define these parameters in a self-consistent way for whatever system context they are modeling.
```math
\begin{aligned}
	f_{y,z,t} \leq \upsilon^{reg}_{y,z} \times \Delta^{total}_{y,z}
	\hspace{4 cm}  \forall y \in \mathcal{W}, z \in \mathcal{Z}, t \in \mathcal{T} \\
	r_{y,z, t} \leq \upsilon^{rsv}_{y,z}\times \Delta^{total}_{y,z}
	\hspace{4 cm}  \forall y \in \mathcal{W}, z \in \mathcal{Z}, t \in \mathcal{T}
	\end{aligned}
```
When charging, reducing the charge rate is contributing to upwards reserve and frequency regulation as it drops net demand. As such, the sum of the charge rate plus contribution to regulation and reserves up must be greater than zero. Additionally, the discharge rate plus the contribution to regulation must be greater than zero.
```math
\begin{aligned}
	&  \Pi_{o,z,t} - f^{charge}_{o,z,t} - r^{charge}_{o,z,t} \geq 0 & \quad \forall o \in \mathcal{O}, z \in \mathcal{Z}, t \in \mathcal{T}\\
	&  \Theta_{o,z,t} - f^{discharge}_{o,z,t} \geq 0 & \quad \forall o \in \mathcal{O}, z \in \mathcal{Z}, t \in \mathcal{T}
\end{aligned}
```
Additionally, when reserves are modeled, the maximum charge rate and contribution to regulation while charging can be no greater than the available energy storage capacity, or the difference between the total energy storage capacity, $\Delta^{total, energy}_{o,z}$, and the state of charge at the end of the previous time period, $\Gamma_{o,z,t-1}$. Note that for storage to contribute to reserves down while charging, the storage device must be capable of increasing the charge rate (which increase net load).
```math
\begin{aligned}
	&  \Pi_{o,z,t} + f^{charge}_{o,z,t} \leq \Delta^{energy, total}_{o,z} - \Gamma_{o,z,t-1} & \quad \forall o \in \mathcal{O}, z \in \mathcal{Z}, t \in \mathcal{T}
\end{aligned}
```
Finally, the constraints on maximum discharge rate are replaced by the following, to account for capacity contributed to regulation and reserves:
```math
\begin{aligned}
	&  \Theta_{o,z,t} + f^{discharge}_{o,z,t} + r^{discharge}_{o,z,t} \leq \Delta^{total}_{o,z} & \quad \forall o \in \mathcal{O}, z \in \mathcal{Z}, t \in \mathcal{T}\\
	&  \Theta_{o,z,t} + f^{discharge}_{o,z,t} + r^{discharge}_{o,z,t} \leq \Gamma_{o,z,t-1} & \quad \forall o \in \mathcal{O}, z \in \mathcal{Z}, t \in \mathcal{T}
\end{aligned}
```
The above reserve related constraints are established by ```storage_all_reserves()``` in ```storage_all.jl```
"""
function storage(EP::Model, inputs::Dict, Reserves::Int, OperationWrapping::Int, LongDurationStorage::Int, EnergyShareRequirement::Int, CapacityReserveMargin::Int, StorageLosses::Int)

	println("Storage Resources Module")
	dfGen = inputs["dfGen"]
	G = inputs["G"]
	T = inputs["T"]
	STOR_ALL = inputs["STOR_ALL"]

	if !isempty(STOR_ALL)
		EP = investment_energy(EP, inputs)
		EP = storage_all(EP, inputs, Reserves, OperationWrapping)

		# Include LongDurationStorage only when modeling representative periods and long-duration storage
		if OperationWrapping == 1 && !isempty(inputs["STOR_LONG_DURATION"])
			EP = long_duration_storage(EP, inputs)
		end
	end

	if !isempty(inputs["STOR_ASYMMETRIC"])
		EP = investment_charge(EP, inputs)
		EP = storage_asymmetric(EP, inputs, Reserves)
	end

	if !isempty(inputs["STOR_SYMMETRIC"])
		EP = storage_symmetric(EP, inputs, Reserves)
	end

	# ESR Lossses
	if EnergyShareRequirement >= 1
		@expression(EP, eESRStor[ESR=1:inputs["nESR"]], sum(inputs["dfESR"][:,ESR][z]*StorageLosses*sum(EP[:eELOSS][y] for y in intersect(dfGen[dfGen.Zone.==z,:R_ID],STOR_ALL)) for z=findall(x->x>0,inputs["dfESR"][:,ESR])))
		EP[:eESR] -= eESRStor
	end

	# Capacity Reserves Margin policy
	if CapacityReserveMargin > 0
		@expression(EP, eCapResMarBalanceStor[res=1:inputs["NCapacityReserveMargin"], t=1:T], sum(dfGen[y,Symbol("CapRes_$res")] * (EP[:vP][y,t] - EP[:vCHARGE][y,t])  for y in STOR_ALL))
		EP[:eCapResMarBalance] += eCapResMarBalanceStor
	end

	return EP
end