function f(a, b, c) 
	a=b
	b=c
end

function f(...) 
	b=c
end

function f(a, b, c, ...) 
	b=c
end

function f()
end


function f1.f2.f3(a)
	a=3
end

function f1.f2.f3:f4(a)
	a=3
end
