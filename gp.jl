### A Pluto.jl notebook ###
# v0.12.20

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : missing
        el
    end
end

# ╔═╡ c823a222-6e1c-11eb-18a8-01a1b673d7b0
begin
	import Pkg; 
	Pkg.add("LinearAlgebra")	
	Pkg.add("Random")
	Pkg.add("PlutoUI")
	Pkg.add("Plots")
	Pkg.add("Plotly")
	using LinearAlgebra
	using Random
	using Plots
    using PlutoUI
	md""" **0) import packages** """
end

# ╔═╡ 53b7c092-6e9b-11eb-0fa7-57fc1385457c
md"
# _The Gaussian Process_
Given a vector of pivot points $\boldsymbol x$,
the corresponding random vector  $\boldsymbol y(\boldsymbol x)$
is drawn from a multivariate Gaussian 

$\boldsymbol z \sim {\cal G}(\mu,C)$

with zero mean $\boldsymbol \mu  = \boldsymbol0$
and a covariance with matrix elements: $C_{ij} = C(x_i,x_j)$.



The different Gaussian processes differ in the kernel function $C(x,y)$

1) Straight line process: $C(x,y) = \alpha \cdot x\cdot y$

2) Wiener process: $C(x,y) = \alpha * min(x, y)$

3) Squared exponential kernel: $C(x,y) = \alpha * \exp(- \frac{(x-y)^2}{\sigma^2})$

4) Ornstein-Uhlenbeck process: $C(x,y) = \alpha * \exp(- \frac{|x-y|}{\sigma})$

GPs are magic ✨ 
"

# ╔═╡ 0ac101ba-6ecc-11eb-090e-6b5998c6bbfd
md"
## Setting up the mathematical details
"

# ╔═╡ dca69d60-6e8c-11eb-3305-3fa2cedd5dac
begin
	Nslide = 100
	L_𝛼  = [0 100 ; 0.01 20 ; 0.01 40 ; 0.1 10]
	L_𝜎 = [-1 -1; -1 -1; 0.1 20; 1 20]
	L_d_𝛼 = 	(L_𝛼[:,2]-L_𝛼[:,1])/Nslide
	L_d_𝜎 = 	(L_𝜎[:,2]-L_𝜎[:,1])/Nslide
	md"""**2) range of parameters**"""
end

# ╔═╡ 1edc6c32-6e1d-11eb-2f8a-b9dd2aff7b99
begin
	L_x0 = [-25:0.5:25;]
	md""" **3) pivot points** """
end

# ╔═╡ 21cff596-6ecc-11eb-093c-f97fac9ab7cb
md"
## Try it out! 
"

# ╔═╡ 2837bf6e-6eb2-11eb-2b2a-190fa3669085
md"""
**Choose a kernel:** $(@bind kernel Select(["1"=>"Straight lines","2"=>"Wiener process","3"=>"Squared exponential","4"=>"Ornstein-Uhlenbeck process"]))
"""

# ╔═╡ 0bef3462-6e1d-11eb-08f6-e3b2c36a0721

begin

if kernel == "1"
		txt = "Straight line";
		L_x    = L_x0;		
		K(x, y, 𝛼, sigma) = 𝛼 * x * y;
	elseif kernel == "2"
		txt = "Wiener process";
		L_x    = [x for x in L_x0 if x >= 0];
		K(x, y, 𝛼, sigma) = 𝛼 * min(x, y);
	elseif kernel == "3"
		txt = "Squared exponential";
		L_x    = L_x0;
		K(x, y, 𝛼, 𝜎) = 𝛼 * exp(- (x - y)^2/𝜎^2);
	elseif kernel == "4"
		txt = "Ornstein-Uhlenbeck process";
		L_x    = L_x0;
		K(x, y, 𝜶, 𝜎) = 𝜶 * exp(abs(x - y)/𝜎);
	else
		error("$(kernel) not supported")
	end	
	n = length(L_x);
	md"""**1) kernel definitions**"""
end

# ╔═╡ bc5fc60a-6e92-11eb-0003-b58331ceddcf
ik = parse(Int32,kernel);

# ╔═╡ 6be2bb7a-6eb6-11eb-2cfb-87383e68bf54
md"
**Specify the seed value of random number generator**  

1 $(@bind seed Slider(1:1000)) 1000
"

# ╔═╡ 05d7032c-6e25-11eb-0b48-7f9a594b5b88
begin
	rng = MersenneTwister(seed)
	u = randn(rng,n, 1)
	md"""**4) normal random vector zero mean, unit variance**"""
end

# ╔═╡ 4fdde52e-6e8b-11eb-3199-8112d143a31a
md"""
The seed you chose: $(seed)
"""


# ╔═╡ 431df5da-6eb4-11eb-11af-898fdf3601d5
	if L_𝜎[ik,2] > 0
		md"""**Choose parameters 𝛼:**
	$(L_𝛼[ik,1]) $(@bind 𝛼 Slider(L_𝛼[ik,1]:L_d_𝛼[ik]:L_𝛼[ik,2])) $(L_𝛼[ik,2]) **and 𝜎:**
		$(L_𝜎[ik,1]) $(@bind 𝜎 Slider(L_𝜎[ik,1]:L_d_𝜎[ik]:L_𝜎[ik,2])) $(L_𝜎[ik,2])
		"""
	else
		𝜎 = L_𝜎[ik,2]
				md"""**Choose parameter 𝛼:**
	$(L_𝛼[ik,1]) $(@bind 𝛼 Slider(L_𝛼[ik,1]:L_d_𝛼[ik]:L_𝛼[ik,2])) $(L_𝛼[ik,2]) 
	"""
	end

# ╔═╡ 2506c99c-6e1d-11eb-31a2-dd1b99a80d8a
begin
	C = [K(x, y, 𝛼, 𝜎) for x in L_x, y in L_x];
	F = svd(C);
	A = F.U * Diagonal(sqrt.(F.S));	
	z = A * u;
	md""" **5) sample from mvG** """
end


# ╔═╡ ac913758-6e27-11eb-1649-37b1be855f5b
if L_𝜎[ik,2] > 0
	md" 	𝛼 = $(𝛼),    𝜎 = $(𝜎)		"
else
	md" 	𝛼 = $(𝛼)"
end

# ╔═╡ b3e26166-6e1e-11eb-1708-25be9e2a339f
plot(
    L_x,
    z,
	line =(1,1,:line),
    grid = true,
    title = txt,
    palette = :tab10,
    legend = :none,
    label = false,
    marker = :cross,
    xlabel = "x",
    ylabel = "y",
    ylim = (-20, 20),
)

# ╔═╡ Cell order:
# ╟─53b7c092-6e9b-11eb-0fa7-57fc1385457c
# ╟─0ac101ba-6ecc-11eb-090e-6b5998c6bbfd
# ╟─c823a222-6e1c-11eb-18a8-01a1b673d7b0
# ╟─0bef3462-6e1d-11eb-08f6-e3b2c36a0721
# ╟─dca69d60-6e8c-11eb-3305-3fa2cedd5dac
# ╟─1edc6c32-6e1d-11eb-2f8a-b9dd2aff7b99
# ╟─05d7032c-6e25-11eb-0b48-7f9a594b5b88
# ╟─2506c99c-6e1d-11eb-31a2-dd1b99a80d8a
# ╟─21cff596-6ecc-11eb-093c-f97fac9ab7cb
# ╟─2837bf6e-6eb2-11eb-2b2a-190fa3669085
# ╟─bc5fc60a-6e92-11eb-0003-b58331ceddcf
# ╟─6be2bb7a-6eb6-11eb-2cfb-87383e68bf54
# ╟─4fdde52e-6e8b-11eb-3199-8112d143a31a
# ╟─431df5da-6eb4-11eb-11af-898fdf3601d5
# ╟─ac913758-6e27-11eb-1649-37b1be855f5b
# ╟─b3e26166-6e1e-11eb-1708-25be9e2a339f
