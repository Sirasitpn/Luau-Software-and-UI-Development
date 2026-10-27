# Luau-Software-and-UI-Development

These are example codes of the simulator game. The main concept of the game is for the players to simulate being a high jumper and encourage players to chase higher attributes like in game currency and jump power, though this project is far from completetion. 

UIManager.lua: 
    An Object-Oriented UI controller utilizing metatables and modular methods (__index, setmetatable) to dynamically generate and manage the Heads-Up Display. It handles client-side state listeners, implements TweenService for smooth transitions, and dynamically renders inventory arrays into interactive UI components.

GameManager.lua: 
    The core server-side backend module. It establishes a secure event-driven architecture using RemoteEvents to handle client requests. It enforces server-side validation (such as cooldown timers via os.clock()) to prevent spam, and manages player attributes like jump power, bar height indexes, and currency

AnimationManager.lua: 
    A resource management module that pre-loads and caches character animations into a dictionary for optimized runtime performance. 
