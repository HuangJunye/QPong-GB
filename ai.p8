pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
-- math.p8
-- This code is part of Qiskit.
--
-- Copyright IBM 2020

-- Custom math table for compatibility with the Pico8

math = {}
math.pi = 3.14159
math.max = max
math.sqrt = sqrt
math.floor = flr
function math.random()
  return rnd(1)
end
function math.cos(theta)
  return cos(theta/(2*math.pi))
end
function math.sin(theta)
  return -sin(theta/(2*math.pi))
end
function math.randomseed(time)
end
os = {}
function os.time()
end

-- MicroQiskit.lua

-- This code is part of Qiskit.
--
-- Copyright IBM 2020

math.randomseed(os.time())

function QuantumCircuit ()

  local qc = {}

  local function set_registers (n,m)
    qc.num_qubits = n
    qc.num_clbits = m or 0
  end
  qc.set_registers = set_registers

  qc.data = {}

  function qc.initialize (ket)
    ket_copy = {}
    for j, amp in pairs(ket) do
      if type(amp)=="number" then
        ket_copy[j] = {amp, 0}
      else
        ket_copy[j] = {amp[0], amp[1]}
      end
    end
    qc.data = {{'init',ket_copy}}
  end

  function qc.add_circuit (qc2)
    qc.num_qubits = math.max(qc.num_qubits,qc2.num_qubits)
    qc.num_clbits = math.max(qc.num_clbits,qc2.num_clbits)
    for g, gate in pairs(qc2.data) do
      qc.data[#qc.data+1] = ( gate )    
    end
  end
      
  function qc.x (q)
    qc.data[#qc.data+1] = ( {'x',q} )
  end

  function qc.rx (theta,q)
    qc.data[#qc.data+1] = ( {'rx',theta,q} )
  end

  function qc.h (q)
    qc.data[#qc.data+1] = ( {'h',q} )
  end

  function qc.cx (s,t)
    qc.data[#qc.data+1] = ( {'cx',s,t} )
  end

  function qc.measure (q,b)
    qc.data[#qc.data+1] = ( {'m',q,b} )
  end

  function qc.rz (theta,q)
    qc.h(q)
    qc.rx(theta,q)
    qc.h(q)
  end

  function qc.ry (theta,q)
    qc.rx(math.pi/2,q)
    qc.rz(theta,q)
    qc.rx(-math.pi/2,q)
  end

  function qc.z (q)
    qc.rz(math.pi,q)
  end

  function qc.y (q)
    qc.z(q)
    qc.x(q)
  end

  return qc

end

function simulate (qc, get, shots)

  if not shots then
    shots = 1024
  end

  function as_bits (num,bits)
    -- returns num converted to a bitstring of length bits
    -- adapted from https://stackoverflow.com/a/9080080/1225661
    local bitstring = {}
    for index = bits, 1, -1 do
        b = num - math.floor(num/2)*2
        num = math.floor((num - b) / 2)
        bitstring[index] = b
    end
    return bitstring
  end

  function get_out (j)
    raw_out = as_bits(j-1,qc.num_qubits)
    out = ""
    for b=0,qc.num_clbits-1 do
      if outputnum_clbitsap[b] then
        out = raw_out[qc.num_qubits-outputnum_clbitsap[b]]..out
      end
    end
    return out
  end


  ket = {}
  for j=1,2^qc.num_qubits do
    ket[j] = {0,0}
  end
  ket[1] = {1,0}

  outputnum_clbitsap = {}

  for g, gate in pairs(qc.data) do

    if gate[1]=='init' then

      for j, amp in pairs(gate[2]) do
          ket[j] = {amp[1], amp[2]}
      end

    elseif gate[1]=='m' then

      outputnum_clbitsap[gate[3]] = gate[2]

    elseif gate[1]=="x" or gate[1]=="rx" or gate[1]=="h" then

      j = gate[#gate]

      for i0=0,2^j-1 do
        for i1=0,2^(qc.num_qubits-j-1)-1 do
          b1=i0+2^(j+1)*i1 + 1
          b2=b1+2^j

          e = {{ket[b1][1],ket[b1][2]},{ket[b2][1],ket[b2][2]}}

          if gate[1]=="x" then
            ket[b1] = e[2]
            ket[b2] = e[1]
          elseif gate[1]=="rx" then
            theta = gate[2]
            ket[b1][1] = e[1][1]*math.cos(theta/2)+e[2][2]*math.sin(theta/2)
            ket[b1][2] = e[1][2]*math.cos(theta/2)-e[2][1]*math.sin(theta/2)
            ket[b2][1] = e[2][1]*math.cos(theta/2)+e[1][2]*math.sin(theta/2)
            ket[b2][2] = e[2][2]*math.cos(theta/2)-e[1][1]*math.sin(theta/2)
          elseif gate[1]=="h" then
            for k=1,2 do
              ket[b1][k] = (e[1][k] + e[2][k])/math.sqrt(2)
              ket[b2][k] = (e[1][k] - e[2][k])/math.sqrt(2)
            end
          end

        end
      end

    elseif gate[1]=="cx" then

      s = gate[2]
      t = gate[3]

      if s>t then
        h = s
        l = t
      else
        h = t
        l = s
      end

      for i0=0,2^l-1 do
        for i1=0,2^(h-l-1)-1 do
          for i2=0,2^(qc.num_qubits-h-1)-1 do
            b1 = i0 + 2^(l+1)*i1 + 2^(h+1)*i2 + 2^s + 1
            b2 = b1 + 2^t
            e = {{ket[b1][1],ket[b1][2]},{ket[b2][1],ket[b2][2]}}
            ket[b1] = e[2]
            ket[b2] = e[1]
          end
        end
      end

    end

  end

  if get=="statevector" then
    return ket
  else

    probs = {}
    for j,amp in pairs(ket) do
      probs[j] = amp[1]^2 + amp[2]^2
    end

    if get=="expected_counts" then

      c = {}
      for j,p in pairs(probs) do
        out = get_out(j)
        if c[out] then
          c[out] = c[out] + probs[j]*shots
        else
          if out then -- in case of pico8 weirdness
            c[out] = probs[j]*shots
          end
        end
      end
      return c

    else

      m = {}
      for s=1,shots do
        cumu = 0
        un = true
        r = math.random()
        for j,p in pairs(probs) do
          cumu = cumu + p
          if r<cumu and un then
            m[s] = get_out(j)
            un = false
          end
        end
      end

      if get=="memory" then
        return m

      elseif get=="counts" then
        c = {}
        for s=1,shots do
          if c[m[s]] then
            c[m[s]] = c[m[s]] + 1
          else
            if m[s] then -- in case of pico8 weirdness
              c[m[s]] = 1
            else
              if c["error"] then
                c["error"] = c["error"]+1
              else
                c["error"] = 1
              end
            end
          end
        end
        return c

      end

    end

  end

end

-- QPong

started=false
ended=false
scored = ""
blink_timer = 0

function newgame()
	started = true
	ended = false
	player_points = 0
	com_points = 0

    --variables
    counter=0
    player={
        x = 117,
        y = 63,
        color = 12,
        width = 2,
        height = 10,
        speed = 1
    }
    com={
        x = 8,
        y = 63,
        color = 8,
        width = 2,
        height = 10,
        speed = 0.3
    }
    ball={
        x = 63,
        y = 20 + rnd(40),
        color = 7,
        width = 2,
        dx = -0.6,
        dy = rnd()-0.5,
        speed = 1,
        speedup = 0.05
    }
    gate_type={
        x = 0,
        y = 1,
        z = 2,
        h = 3
    }
    gate_seq={
      I=1,
      X=2,
      Y=3,
      Z=4,
      H=5
    }
    gates={
		{1,1,1,1,1,1,1,1},
		{1,1,1,1,1,1,1,1},
		{1,1,1,1,1,1,1,1}
	}
	-- Relative frequency of the measurement results
	-- Obtained from simulator
	probs = {1, 0, 0, 0, 0, 0, 0, 0}
  --probs={0.5, 0.5, 0, 0, 0, 0, 0, 0}
  --meas_probs={1, 0, 0, 0, 0, 0, 0, 0}

	-- How many updates left does the paddle stays measured
	measured_timer = 0

    cursor = {
        row=0,
        column=0,
        x=0,
        y=0,
        sprite=16
    }
    --sound
    if scored=="player" then
        sfx(3)
    elseif scored=="com" then
        sfx(4)
    else
        sfx(5)
    end
	--court
    court={
        left=0,
        right=127,
        top=0,
        bottom=82,
        edge=107, --when ball collide this line, measure the circuit
        color=5
    }
	--court center line
    dash_line={
        x=63,
        y=0,
        length=1.5,
        color=5
    }
    --circuit composer
    composer={
        left=0,
        right=127,
        top=82,
        bottom=127,
        color=7
    }
    qubit_line={
        x=10,
        y=90,
        length=108,
        separation=15,
        color=5
    }
end

function newRound()
    ball={
        x = 63,
        y = 20 + rnd(40),
        color = 7,
        width = 2,
        dx = -1,
        dy = rnd()-0.5,
        speed = 1,
        speedup = 0.05
    }
end

function _draw()
    cls()

	if not started then
		if blink_timer < 40 then
			print("press z", 50, 80, 10)
		end

		for i = 0, 10 do
			for j = 0, 3 do
				spr(64 + i + 16 * j,
					20 + 8 * i,
					30 + 8 * j)
			end
		end

		for i = 0,2 do
		  --print IBM logo
		  spr(i+140,i*8+64,104)
		  spr(i+156,i*8+64,112)
		  --print NTU logo
		  spr(i+172,i*8+104,104)
		  spr(i+188,i*8+104,112)
		end
		spr(160,92,112)

	elseif ended then
    if scored == "player" then
      for i = 0,1 do
        for j = 0,2 do
          spr(217+j+16*i,36+8*j,60+8*i)
        end
      end
      
      for i =0,1 do
        for j=0,3 do
          spr(220+j+16*i,65+8*j,60+8*i)
        end
      end 
        else
            for i = 0,1 do
        for j = 0,8 do
          spr(208+j+16*i,28+8*j,40+8*i)
        end
      end 
      print("CLASSICAL COMPUTER",30,70,10)
      print("STILL RULES THE WORLD",25,80,10) 
        end
        print("PRESS Z TO RESTART", 30, 110, 10)
	else --game is running
		--court
		rect(court.left,court.top,court.right,court.bottom,court.color)

		--dashed center line
		repeat
			line(dash_line.x,dash_line.y,dash_line.x,dash_line.y+dash_line.length,dash_line.color)
			dash_line.y += dash_line.length*2
		until dash_line.y > court.bottom-1
		dash_line.y = 0 --reset

		--circuit composer
		rectfill(composer.left,composer.top,composer.right,composer.bottom,composer.color)
		--qubit lines
		repeat
			line(qubit_line.x,qubit_line.y,qubit_line.x+qubit_line.length,qubit_line.y,qubit_line.color)
			qubit_line.y += qubit_line.separation
		until qubit_line.y > composer.bottom-1
		qubit_line.y = 90 --reset

		for slot = 1, 8 do
			for wire = 1, 3 do
				gnum = gates[wire][slot] - 2
				if gnum != -1 then
					spr(gnum,
						qubit_line.x + (slot - 1) * qubit_line.separation - 4,
						qubit_line.y + (wire - 1) * qubit_line.separation - 4)
				end
			end
		end

		--cursor
		cursor.x=qubit_line.x+cursor.column*qubit_line.separation-4
		cursor.y=qubit_line.y+cursor.row*qubit_line.separation-4
		spr(cursor.sprite,cursor.x,cursor.y)

		for x=0,7 do
			spr(6, 94, 10 * x + 2)
			a=x%2
			b=flr(x/2)%2
			c=flr(x/4)%2
			spr(c+4, 97, 10 * x + 2)
			spr(b+4, 102, 10 * x + 2)
			spr(a+4, 107, 10 * x + 2)
			spr(7, 111, 10 * x + 2)
		end



		--ball
		rectfill(
			ball.x,
			ball.y,
			ball.x + ball.width,
			ball.y + ball.width,
			ball.color
		)

		--computer
		rectfill(
			com.x,
			com.y,
			com.x + com.width,
			com.y + com.height,
			com.color
		)
        --player
        rectfill(
			player.x,
			player.y,
			player.x + com.width,
			player.y + player.height,
			player.color
		)

		--scores
		print(player_points,66,2,player.color)
		print(com_points,58,2,com.color)
	end


end


function simCir()
    qc = QuantumCircuit()
    qc.set_registers(3,3)
    for slots = 1,8 do
      for wires = 1,3 do
       if (gates[wires][slots] == 2) then 
          qc.x(wires-1)
        
        elseif (gates[wires][slots] == 3) then 
          qc.y(wires-1)
        
        elseif (gates[wires][slots] == 4) then
          qc.z(wires-1)
       
        elseif (gates[wires][slots] == 5) then 
          qc.h(wires-1)  
        end 
      end          
    end

    qc.measure(0,0)
    qc.measure(1,1)
    qc.measure(2,2)
    
    result = simulate(qc,'expected_counts',1)

    for key, value in pairs(result) do
      print(key,value)
      idx = tonum('0b'..key) + 1
      probs[idx]=value
    end  
end

function meas_prob()
    idx = -1
    math.randomseed(os.time())
    r=math.random()
    --r =0.2
    --print(r)
    num =0
    for i = 1,8 do
        
        if (r > probs[i]) then
            num=r-probs[i]
            r=num
        
        elseif (r<=probs[i]) then 
            idx = i
            break
        end
    end
    for i = 1,8 do
        if i==idx then
            probs[i]=1
        else
            probs[i]=0
        end
    end
    return idx
end

function _update60()
	blink_timer = (blink_timer + 1) % 60
    --player controls
    
	if (not started) or ended then
		if btnp(4) then
			newgame()
		end
	else
		if btnp(2)
		and cursor.row > 0 then
			cursor.row -= 1
		end
		if btnp(3)
		and cursor.row < 2 then
			cursor.row += 1
		end
		if btnp(0)
		and cursor.column > 0 then
			cursor.column -= 1
		end
		if btnp(1)
		and cursor.column < 7  then
			cursor.column += 1
		end
		if btnp(5) then 
		  cur_gate = gates[cursor.row+1][cursor.column+1]
		  if cur_gate==2 then
			gates[cursor.row+1][cursor.column+1]=1
		  else
			gates[cursor.row+1][cursor.column+1]=2
		  end
		  simCir()
		end
		if btnp(4) then 
		  cur_gate = gates[cursor.row+1][cursor.column+1]
		  if cur_gate==5 then
			gates[cursor.row+1][cursor.column+1]=1
		  else
			gates[cursor.row+1][cursor.column+1]=5
		  end
		  simCir()
		end


		--computer controls
		mid_com = com.y + (com.height/2)

		if ball.dx<0 then
			if mid_com > ball.y
			and com.y>court.top+1 then
				com.y-=com.speed
			end
			if mid_com < ball.y
			and com.y + com.height < court.bottom - 1 then
				com.y += com.speed
			end
		else
			if mid_com > 73 then
				com.y -= com.speed
			end
			if mid_com < 53 then
				com.y += com.speed
			end
		end
    

        mid_play=player.y+(player.height/2)
		if ball.dx>0 then
			if mid_play > ball.y
			and player.y>court.top+1 then
				player.y-=player.speed
			end
			if mid_play< ball.y
			and player.y + player.height < court.bottom - 1 then
				player.y += player.speed
			end
		else
			if mid_play > 73 then
				player.y -= player.speed
			end
			if mid_play < 53 then
				player.y += player.speed
			end
		end
  	--score
		if ball.x > court.right then
			com_points += 1
			scored = "com"
			if com_points < 7 then
				newRound()
			else
				ended = true
			end
		end
		if ball.x < court.left then
			player_points += 1
			scored = "player"
			if player_points < 7 then
				newRound()
			else
				ended = true
			end
		end
    --collide with court
		if ball.y + ball.width >= court.bottom - 1
		or ball.y <= court.top+1 then
			ball.dy = -ball.dy
			sfx(2)
		end

		--collide with com
		if ball.dx < 0
    and ball.x <= com.x+com.width
    and ball.x >com.x 
		and ((ball.y+ball.width<=com.y+com.height and ball.y+ball.width>=com.y)or(ball.y<=com.y+com.height and ball.y>=com.y))
		then
			ball.dy -= ball.speedup*2
			--flip ball DX and add speed
			ball.dx = -(ball.dx - ball.speedup)
			sfx(1)
		end
		--TODO: when ball collide on edge--> measure
		--UNTEST
		------------------------

		--collide with player
		if ball.dx > 0
    and ball.x <= player.x+player.width
		and ball.x> player.x
		and ((ball.y+ball.width<=player.y+player.height and ball.y+ball.width>=player.y)or(ball.y<=player.y+player.height and ball.y>=player.y))
		then
			ball.dy -= ball.speedup*2
			--flip ball DX and add speed
			ball.dx = -(ball.dx - ball.speedup)
			sfx(1)
		end




		--ball movement
		ball.x += ball.dx
		ball.y += ball.dy
	end
end

__gfx__
66666661666666616666666166666661000000000000000010000000010000000000000000000000000000000000000000000000000000000000000000000000
61666161616661616111116161666161011000000010000010000000001000000000000000000000000000000000000000000000000000000000000000000000
66161661661616616666166161666161100100000110000010000000001000000000000000000000000000000000000000000000000000000000000000000000
66616661666166616661666161111161100100000010000010000000000100000000000000000000000000000000000000000000000000000000000000000000
66161661666166616616666161666161100100000010000010000000000100000000000000000000000000000000000000000000000000000000000000000000
61666161666166616111116161666161011000000010000010000000001000000000000000000000000000000000000000000000000000000000000000000000
66666661666666616666666166666661000000000000000010000000001000000000000000000000000000000000000000000000000000000000000000000000
11111111111111111111111111111111000000000000000010000000010000000000000000000000000000000000000000000000000000000000000000000000
c0c0c0c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0c0c0c0c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11000000000000000000000000001110000000001100000000000000000000000000001100000000000000000000000000000000000000000000000000000000
11000000000000000000000000000111000000001100000000000000000000000000000110000000000000000000000000000000000000000000000000000000
11000000000099999999000000000011000000001100000000000000000000000000000110000000000000000000000000000000000000000000000000000000
11000000000999999999900000000001100000001100099999999999990000000000000011000000000000000000000000000000000000000000000000000000
11000000099900000009990000000001100000001100099999999999999000000000000011100000000000000000000000000000000000000000000000000000
11000000999900000000999000000000110000001100099900000000999000000000000001100000000000000000000000000000000000000000000000000000
11000009990000000000099900000000110000001100099900000000099000000000000000110000000000000000000000000000000000000000000000000000
11000009900000000000009990000000111000001100099900000000099000000000000000110000000000000000000000000000000000000000000000000000
11000099900000000000000990000000011000001100099900000000009900000000000000011000000000000000000000000000000000000000000000000000
11000099900000000000000999000000011000001100099900000000009900000000000000011100000000000000000000000000000000000000000000000000
11000099000000000000000099000000001100001100099900000000009900000000000000001100000000000000000000000000000000000000000000000000
11000999000000000000000099000000001100001100099900000000009900000000000000001110000000000000000000000000000000000000000000000000
11000990000000000000000099000000000100001100099900000000099000000000000000000110000000000000000000000000000000000000000000000000
11000990000000000000000099000000000110001100099900000000999000000000000000000011000000000000000000000000000000000000000000000000
11000990000000000000000009900000000011001100099999999999990000000000000000000011000000000000000000000000000000000000000000000000
11000990000000000000000009900000000011001100099999999999000000000000000000000001100000000000000000000000000000000000000000000000
11000990000000000000000009900000000011001100099000000000000000000000000000000001100000000000000000000000000000000000000000000000
11000999000000000009900009900000000110001100099000000000000000000000000000000011000000000000000000000000000000000000000000000000
11000999000000000009900099000000000100001100099000000000000000000000000000000011000000000000000000000000000000000000000000000000
11000099000000000009990099000000001100001100099000000000000000000000000000000110000000000000000000000000000000000000000000000000
11000099000000000000999099000000001100001100099000099900090990000990000000000110000000000000000000000000000000000000000000000000
11000009900000000000099090000000011000001100099000990990099009009009000000000100000000000000000000000000000000000000000000000000
11000009900000000000009990000000111000001100099000900090090009009009000000001100000000000000000000000000000000000000000000000000
11000009990000000000099900000000110000001100099000990990090009000999000000001100000000000000000000000000000000000000000000000000
11000000999000000009999990000001100000001100099000099900090009000009900000001000000000000000000000000000000000000000000000000000
11000000009999000999990999000001100000001100099000000000000000000099000000011000000000000000000000000000000000000000000000000000
11000000000999999999000099900011000000001100000000000000000000000909000000011000000000000000000000000000000000000000000000000000
11000000000000999000000009900011000000001100000000000000000000009009000000110000000000000000000000000000000000000000000000000000
11000000000000000000000000000110000000001100000000000000000000009090000001100000000000000000000000000000000000000000000000000000
11000000000000000000000000000110000000001100000000000000000000000900000001100000000000000000000000000000000000000000000000000000
11000000000000000000000000001100000000001100000000000000000000000000000011000000000000000000000000000000000000000000000000000000
11000000000000000000000000001100000000001100000000000000000000000000000011000000000000000000000000000000000000000000000000000000
cccccccc0cccccccccccc000ccccc000000000ccccc00000111000000000111088888888888880333000000333000000cccc0cccccc00cc0000000cc00000000
00000000000000000000000000000000000000000000000011110000000011108888888888888033300000033300000000000000000000000000000000000000
cccccccc0ccccccccccccc00cccccc0000000cccccc00000111110000000111088888888888880333000000333000000cccc0ccc0ccc0ccc00000ccc00000000
00000000000000000000000000000000000000000000000011111100000011100000088800000033300000033300000000000000000000000000000000000000
00cccc00000ccc00000ccc0000ccccc00000ccccc00000001111111000001110000008880000003330000003330000000cc000c00ccc00ccc000ccc000000000
00000000000000000000000000000000000000000000000011111111000011100000088800000033300000033300000000000000000000000000000000000000
00cccc00000ccccccccc000000cccccc000cccccc00000001110111110001110000008880000003330000003330000000cc000ccccc000cccc0cccc000000000
00000000000000000000000000000000000000000000000011100111110011100000088800000033300000033300000000000000000000000000000000000000
00cccc00000ccccccccc000000ccc0ccc0ccc0ccc00000001110001111101110000008880000003330000003330000000cc000c00cc000cc0c0c0cc000000000
00000000000000000000000000000000000000000000000011100001111111100000088800000033300000033300000000000000000000000000000000000000
00cccc00000ccc00000ccc0000ccc00ccccc00ccc00000001110000011111110000008880000003330000003330000000cc000c00ccc00cc0ccc0cc000000000
00000000000000000000000000000000000000000000000011100000011111100000088800000033300000033300000000000000000000000000000000000000
cccccccc0ccccccccccccc00ccccc000ccc000ccccc00000111000000011111000000888000000333300003333000000cccc0ccccccc0ccc00c00ccc00000000
00000000000000000000000000000000000000000000000011100000000111100000088800000033333333333300000000000000000000000000000000000000
cccccccc0cccccccccccc000ccccc0000c0000ccccc00000111000000000111000000888000000033333333330000000cccc0cccccc00ccc00000ccc00000000
00000000000000000000000000000000000000000000000011100000000011100000088800000003333333333000000000000000000000000000000000000000
0eeeeee00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dd00000dd88888888330003300000000
e000000e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dd00000dd88888888330003300000000
e0e00e0e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dd00000dd00088000330003300000000
e00ee00e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dd00000dd00088000330003300000000
e00ee00e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ddd0000dd00088000330003300000000
e0e00e0e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dddd000dd00088000330003300000000
e000000e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ddddd00dd00088000330003300000000
0eeeeee00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dddddd0dd00088000330003300000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ddddddddd00088000330003300000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dd0dddddd00088000330003300000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dd00ddddd00088000330003300000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dd000dddd00088000330003300000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dd0000ddd00088000330003300000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dd00000dd00088000333033300000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dd00000dd00088000333333300000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dd00000dd00088000033333000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000099999900999900999099900099999000999000900000090099999990099999000009000009000999000900090090000009000000900999990099000090
00000990000900999900999099900900009009000900900000090090000090090000900000900090009000900900090090000090900000900009000099000090
00000990000000900900909090900900000009000900900000090090000000090000900000090900009000900900090090000090900000900009000090900090
00000990000000900900909090900900000009000900090000900090000000090000900000009000009000900900090009000900090009000009000090900090
00000990099900900900909090900999999009000900090000900099999990099999000000009000009000900900090009000900090009000009000090090090
00000990009900900900909090900900000009000900090000900090000000090990000000009000009000900900090009000900090009000009000090090090
00000990000900999900909090900900000009000900009009000090000000090090000000009000009000900900090000909000009090000009000090009090
00000990000900900900909090900900000009000900009009000090000000090009000000009000009000900900090000909000009090000009000090009090
00000990000900900900909990900900009009000900009009000090000090090000900000009000009000900900090000909000009090000009000090000990
00000099999900900900900900900099999000999000000990000099999990090000090000009000000999000099900000090000000900000999990090000990