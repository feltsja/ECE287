# ECE287 Simon Says game README

This project is for my ECE 287 class final project where we had to design something on our own 
or in groups to present as a final project to show our understanding throughout the semester in the course. 
I chose to do this project alone and created a Simon Says game on the De2-115 board that can be used with a 
VGA display connected to a monitor for the game.

# The creation of the Simon Says game

The beginning of this project began at the simple idea of being able to run Simon Says on the DE2-115 board. This started as 
being able to run the game on just the board before moving towards the idea of getting it displayed via the VGA display. 
A more in-depth understanding of the inside of the project can be found within the [Wiki](https://github.com/feltsja/ECE287-Simon-Says/wiki).

# What is included

There will be two separate folders within the directory, one labelled as simon_says_without_vga and the other as 
sim_says_with_vga . The are both self explanatory as one version will be able to run on a DE2-115 board and the sequence 
will appear on the Red LEDs 0 through 2, and the other will have the same board state but will be updated to also use the
VGA display to show the colors correlating with the sequence. Each version is just two files, the simon_says.v and random_number_generator.v .

# How to play the game

Although the pin assignment is explained at the top of the simon_says.v code, I will explain how the game is controlled here.
 SW[17] is the reset and must be flipped on to allow the game to run. Next is SW[16] which is the start switch, which upon being 
 flipped on will start the game by taking in user inputs. The first user inputs will be SW[15:14] as the difficulty controls. 
 Setting the two switches in the following ways will control the difficulty: 00 as easy, 01 as medium, 10 as Hard, 11 as Insane. 
 The main 'difficulty' this changes is how fast the sequence will be revealed before going dark. The last step to begin the game
 will then be by flipping the initialize SW[13] that will lock in the random sequence and move to round 1.

 The round number correlates to how many colours/numbers in the sequence are shown, so round 1 = 1 shown, round 2 = 2 shown, etc etc, 
 all the way to 10 shown on round 10. To begin the round, all that needs pressed is KEY[3] and the sequence will begin to be displayed. 
 After it has been shown it will be your, the user's, turn where SW[2:0] will be used to mimic the sequence in the following way: 
 001 = Red, 010 = Blue, 011 = Yellow, 100 = Green. For each colour/number in the sequence you need to 'lock in' your answer by pressing KEY[0]
  before moving on to the next one. Once you matched all the colours/numbers in the sequence, the round counter will increase and you can start
  the next round by pushing KEY[3] again until completing round 10.

Upon completing round 10, or losing in a previous round, the game can then be reset by flipping down the start, initialize, and reset switches 
(SW[17], SW[16], SW[13]). The steps can then be followed to play again, this time with a different random sequence and a different difficulty
 if chosen in the initialization step. 

# Citations

* [Anthony Roberto & Maggie Mize](https://github.com/ece287/Simon-Says) - For insight on setting up the VGA as guidance
* [Dom](https://www.youtube.com/watch?v=mR-eo7a4n5Q) - A Youtube video/creator that also helping with setting up the VGA
* Dr. Jamieson - For the version of a random number generator that was modified to work as the random sequence creator and for the measurements to use within the VGA display
