package main

import fmt "core:fmt"
import la "core:math/linalg"
import m "core:math/linalg/hlsl"
import rl "vendor:raylib"
import rand "core:math/rand"
import  "core:strings"

Paddle :: struct{
	p : m.float2,
	score : int,
	dim : m.int2,
}

Ball :: struct{
	p : m.float2,
	v : m.float2,
}

player1 : Paddle
player2 : Paddle

ball : Ball

main :: proc(){
	fmt.println("Hello, World!")

	window_dim := m.int2{800, 600}
	rl.InitWindow(window_dim.x, window_dim.y, "Pong")
	rl.SetTargetFPS(60)
	is_running := true
	
	reset_round(&ball,&player1,&player2,window_dim)

	current_speed : f32 = 7.0
	for is_running && !rl.WindowShouldClose(){
		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)

		//integration of velocity into ball position
		ball.p += (ball.v * current_speed)

		//ball collision with wall
		if ball.p.x < 0{
			ball.p.x = 0
			ball.v.x = -ball.v.x
		}else if ball.p.x > f32(window_dim.x){
			ball.p.x = f32(window_dim.x)
			ball.v.x = -ball.v.x
		}else if ball.p.y < 0{
			ball.p.y = 0
			ball.v.y = -ball.v.y
		}else if ball.p.y > f32(window_dim.y){
			ball.p.y = f32(window_dim.y)
			ball.v.y = -ball.v.y
		}

		//handle input for players move paddles 
		if rl.IsKeyDown(rl.KeyboardKey.W){
			player1.p.y -= current_speed
		}else if rl.IsKeyDown(rl.KeyboardKey.S){
			player1.p.y += current_speed
		}

		if rl.IsKeyDown(rl.KeyboardKey.UP){
			player2.p.y -= current_speed
		}else if rl.IsKeyDown(rl.KeyboardKey.DOWN){
			player2.p.y += current_speed
		}

		enfore_paddle_bounds_move(&player1,window_dim)
		enfore_paddle_bounds_move(&player2,window_dim)
		
		paddle_ball_collision_detection(&ball,player1)
		paddle_ball_collision_detection(&ball,player2)

		//check did score
		if ball.p.x < 1{
			player2.score += 1
			reset_round(&ball,&player1,&player2,window_dim)
		}

		if ball.p.x > f32(window_dim.x) - 1{
			player1.score += 1
			reset_round(&ball,&player1,&player2,window_dim)
		}

		//draw paddle and balll
		draw_paddle(player1)
		draw_paddle(player2)
		rl.DrawRectangle(i32(ball.p.x), i32(ball.p.y), 10, 10, rl.WHITE)

		player1_score := strings.clone_to_cstring(fmt.tprintf("P1  %v",player1.score),context.temp_allocator)
		rl.DrawText(player1_score, 100, 100, 20, rl.DARKGRAY)

		player2_score := strings.clone_to_cstring(fmt.tprintf("P2  %v",player2.score),context.temp_allocator)
		rl.DrawText(player2_score, window_dim.x - 100, 100, 20, rl.DARKGRAY)

		rl.EndDrawing()
	}
}

reset_round :: proc(ball : ^Ball,player1 : ^Paddle,player2 : ^Paddle,window_dim : m.int2){
	player1.p = m.float2{100.0,f32(window_dim.y/2)}
	player2.p = m.float2{f32(window_dim.x - 100.0),f32(window_dim.y/2)}
	player1.dim = m.int2{10,40}
	player2.dim = player1.dim

	ball.p = {f32(window_dim.x/2), f32(window_dim.y/2)}

	xdir : f32 = 1.0
	randx := rand.float32_range(0.0,1.0)
	if randx > 0.5{
		xdir = -1.0
	}

	ball.v = la.normalize(m.float2{xdir, rand.float32_range(-0.8, 0.8)})
	fmt.println(ball.v)
}

paddle_ball_collision_detection :: proc(ball : ^Ball, paddle : Paddle){
	//ball collision with paddle
	//NOTE(RAY):This is not going to handle the case 
	//where the ball is hitting the top and bottom of the paddle
	if ball.p.x < paddle.p.x + f32(paddle.dim.x) && 
	ball.p.x > paddle.p.x - f32(paddle.dim.x) && 
	ball.p.y < paddle.p.y + f32(paddle.dim.y) && 
	ball.p.y > paddle.p.y - f32(paddle.dim.y){
		ball.v.x = -ball.v.x
		fmt.println("collision with player1")
	}
}

draw_paddle :: proc(paddle : Paddle){
	paddle_rect := rl.Rectangle{paddle.p.x, paddle.p.y, f32(paddle.dim.x), f32(paddle.dim.y)}
	paddle_origin := la.Vector2f32{paddle_rect.width/2.0,paddle_rect.height/2.0}
	rl.DrawRectanglePro(paddle_rect, paddle_origin ,0, rl.WHITE)
}

enfore_paddle_bounds_move :: proc(paddle : ^Paddle,window_dim : m.int2){
	//handle paddles bounds movement
	if paddle.p.y - (f32(paddle.dim.y) / 2.0) < 0{
		paddle.p.y = (f32(paddle.dim.y)/2.0)
	}else if paddle.p.y + (f32(paddle.dim.y) / 2.0) > f32(window_dim.y){
		paddle.p.y = f32(window_dim.y) - f32(paddle.dim.y/2)
	}
}


