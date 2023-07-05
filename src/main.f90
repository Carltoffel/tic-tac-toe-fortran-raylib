#include "macros.h"

program main
  use iso_c_binding, only: c_int, c_int32_t, C_NULL_CHAR, C_NULL_PTR
  use raylib
  use game
  use ai
  use ui
  implicit none

  ! Measure units:
  ! - *_px - pixels
  ! - *_cl - cells
  ! - *_rl - relative (fraction of width, height, cell size, etc)
  integer(c_int),     parameter :: screen_width_px        = 800
  integer(c_int),     parameter :: screen_height_px       = 600
  integer(c_int),     parameter :: fps                    = 60
  integer(c_int32_t), parameter :: background_color       = color(z'FF181818')
  integer(c_int32_t), parameter :: strikethrough_color    = color(z'FFFFFFFF')
  real,               parameter :: board_padding_rl       = 0.03
  integer, parameter :: hello_chat_font_size = 48
  real, parameter :: button_width = 200
  real, parameter :: button_height = 100

  real    :: dt
  integer :: x_cl, y_cl, next_x_cl, next_y_cl
  real    :: x_px, y_px, s_px
  integer :: window_width_px, window_height_px
  real    :: board_x_px, board_y_px, board_size_px, cell_size_px

  integer,dimension(board_size_cl, board_size_cl) :: board

  integer :: current_player
  type(TLine) :: final_line
  integer :: state
  type(Font) :: game_font

  integer, parameter :: STATE_GAME = 0
  integer, parameter :: STATE_WON  = 1
  integer, parameter :: STATE_TIE  = 2

  state = STATE_GAME
  board(:,:) = reshape((/ &
      0, 0, 0, &
      0, 0, 0, &
      0, 0, 0  &
  /), (/board_size_cl, board_size_cl/))

  current_player = CELL_CROSS

  call set_config_flags(FLAG_WINDOW_RESIZABLE)
  call init_window(screen_width_px, screen_height_px, "Fortran GOTY"//C_NULL_CHAR)
  call set_target_fps(fps)

  ! TODO: set the working directory to where the executable is located
  game_font = load_font_ex("./fonts/Alegreya-Regular.ttf"//C_NULL_CHAR, hello_chat_font_size, C_NULL_PTR, 0)

  do while (.not. window_should_close())
     dt               = get_frame_time()
     window_width_px  = get_render_width()
     window_height_px = get_render_height()

     if (window_width_px > window_height_px) then
        board_size_px = window_height_px
        board_x_px = real(window_width_px)/2 - board_size_px/2
        board_y_px = 0
     else
        board_size_px = window_width_px
        board_x_px = 0
        board_y_px = real(window_height_px)/2 - board_size_px/2
     end if

     cell_size_px = board_size_px/board_size_cl

     call begin_drawing()
     call clear_background(background_color)
     select case (state)
     case (STATE_GAME)
        call render_game_state()
     case (STATE_WON)
        call render_won_state()
     case (STATE_TIE)
        call render_tie_state()
     end select
     call end_drawing()
  end do

contains
  subroutine render_tie_state()
    implicit none
    do x_cl=1,board_size_cl
       do y_cl=1,board_size_cl
          x_px = board_x_px + (x_cl - 1)*cell_size_px + (cell_size_px*board_padding_rl)/2
          y_px = board_y_px + (y_cl - 1)*cell_size_px + (cell_size_px*board_padding_rl)/2
          s_px = cell_size_px - (cell_size_px*board_padding_rl)
          select case (board(x_cl, y_cl))
          case (CELL_EMPTY)
             call empty_cell(x_px, y_px, s_px, cell_regular_color)
          case (CELL_CROSS)
             call cross_cell(x_px, y_px, s_px)
          case (CELL_KNOTT)
             call knot_cell(x_px, y_px, s_px)
          end select
       end do
    end do

    ! TODO: the size of the restart button should depend on the size of the screen
    if (restart_button(game_font, rectangle(board_x_px + board_size_px/2 - button_width/2, &
         board_y_px + board_size_px/2 - button_height/2, &
         button_width, button_height), cross_color)) then
       board(:,:) = 0
       state = STATE_GAME
       current_player = CELL_CROSS
    end if
  end subroutine render_tie_state

  subroutine render_won_state()
    implicit none
    type(Vector2) :: startPos, endPos
    real :: thick
    do x_cl=1,board_size_cl
       do y_cl=1,board_size_cl
          x_px = board_x_px + (x_cl - 1)*cell_size_px + (cell_size_px*board_padding_rl)/2
          y_px = board_y_px + (y_cl - 1)*cell_size_px + (cell_size_px*board_padding_rl)/2
          s_px = cell_size_px - (cell_size_px*board_padding_rl)
          select case (board(x_cl, y_cl))
          case (CELL_EMPTY)
             call empty_cell(x_px, y_px, s_px, cell_regular_color)
          case (CELL_CROSS)
             call cross_cell(x_px, y_px, s_px)
          case (CELL_KNOTT)
             call knot_cell(x_px, y_px, s_px)
          end select
       end do
    end do

    thick = cell_size_px*0.2

    startPos%x = board_x_px + (final_line%x-1)*cell_size_px + cell_size_px/2 + (-final_line%dx)*(cell_size_px/3)
    startPos%y = board_y_px + (final_line%y-1)*cell_size_px + cell_size_px/2 + (-final_line%dy)*(cell_size_px/3)
    endPos%x   = board_x_px + ((final_line%x-1) + 2*final_line%dx)*cell_size_px + cell_size_px/2 + final_line%dx*(cell_size_px/3)
    endPos%y   = board_y_px + ((final_line%y-1) + 2*final_line%dy)*cell_size_px + cell_size_px/2 + final_line%dy*(cell_size_px/3)
    call draw_line_ex(startPos, endPos, thick, strikethrough_color)

    if (restart_button(game_font, rectangle(board_x_px + board_size_px/2 - button_width/2, &
         board_y_px + board_size_px/2 - button_height/2, &
         button_width, button_height), cross_color)) then
       board(:,:) = 0
       state = STATE_GAME
       current_player = CELL_CROSS
    end if
  end subroutine render_won_state

  subroutine render_game_state()
    implicit none
    select case(current_player)
    case (CELL_CROSS)
       do x_cl=1,board_size_cl
          do y_cl=1,board_size_cl
             x_px = board_x_px + (x_cl - 1)*cell_size_px + (cell_size_px*board_padding_rl)/2
             y_px = board_y_px + (y_cl - 1)*cell_size_px + (cell_size_px*board_padding_rl)/2
             s_px = cell_size_px - (cell_size_px*board_padding_rl)
             select case (board(x_cl, y_cl))
             case (CELL_EMPTY)
                if (empty_cell_clickable(x_px, y_px, s_px)) then
                   board(x_cl, y_cl) = current_player
                   if (player_won(board, CELL_CROSS, final_line)) then
                      state = STATE_WON
                      return
                   end if
                   if (player_won(board, CELL_KNOTT, final_line)) then
                      state = STATE_WON
                      return
                   end if
                   current_player = 3 - current_player
                end if
             case (CELL_CROSS)
                call cross_cell(x_px, y_px, s_px)
             case (CELL_KNOTT)
                call knot_cell(x_px, y_px, s_px)
             end select
          end do
       end do
    case (CELL_KNOTT)
       do x_cl=1,board_size_cl
          do y_cl=1,board_size_cl
             x_px = board_x_px + (x_cl - 1)*cell_size_px + (cell_size_px*board_padding_rl)/2
             y_px = board_y_px + (y_cl - 1)*cell_size_px + (cell_size_px*board_padding_rl)/2
             s_px = cell_size_px - (cell_size_px*board_padding_rl)
             select case (board(x_cl, y_cl))
             case (CELL_EMPTY)
                call empty_cell(x_px, y_px, s_px, cell_regular_color)
             case (CELL_CROSS)
                call cross_cell(x_px, y_px, s_px)
             case (CELL_KNOTT)
                call knot_cell(x_px, y_px, s_px)
             end select
          end do
       end do
       if (.not. ai_next_move(board, current_player, next_x_cl, next_y_cl)) then
          board(next_x_cl, next_y_cl) = current_player
          if (player_won(board, CELL_CROSS, final_line)) then
             state = STATE_WON
             return
          end if
          if (player_won(board, CELL_KNOTT, final_line)) then
             state = STATE_WON
             return
          end if
          current_player = 3 - current_player
       else
          state = STATE_TIE
       end if
    end select
  end subroutine render_game_state
end program

! # Roadmap
! - TODO: togglable AI (some sort of checkboxes on the side)
! - TODO: particle effects on placing the shapes
! - TODO: sound effects on placing the shapes and game over
! - TODO: customizable board size
! - TODO: accessibility: control via keyboard
