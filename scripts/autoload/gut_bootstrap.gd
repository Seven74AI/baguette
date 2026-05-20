# Bootstrap script that forces GUT dependencies to be loaded early.
# In headless Godot 4.2, class_name declarations are only globally registered
# when a script is compiled. Editor mode pre-compiles all scripts; headless does not.
# By preloading GutUtils here (as an autoload), we force its compilation at startup
# so that all 31 GUT scripts that reference GutUtils as a class_name can find it.
extends Node

# Force-compile GutUtils and GutTest so class_name is globally registered
# GutTest has the same headless class_name resolution bug as GutUtils
# Project classes also need preloading for GUT headless resolution
const _GUT_UTILS = preload("res://addons/gut/utils.gd")
const _GUT_TEST = preload("res://addons/gut/test.gd")
const _CROISSANT_PROJECTILE = preload("res://scenes/weapons/croissant_projectile.gd")
const _CROISSANT_BOOMERANG = preload("res://scenes/weapons/croissant_boomerang.gd")
const _WEAPON_MANAGER = preload("res://scripts/weapons/weapon_manager.gd")
const _CROISSANT_MESH_GEN = preload("res://scenes/weapons/croissant_mesh_generator.gd")
const _FOUR_SACRE = preload("res://scripts/weapons/four_sacre.gd")
const _PISTOLET_ENCRE = preload("res://scripts/weapons/pistolet_encre.gd")
