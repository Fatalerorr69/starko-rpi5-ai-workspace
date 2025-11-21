# web_gui/core/__init__.py
"""Core utilities for WebGUI — small bootstrap file."""


# exponuj jména, která chceme importovat z core
from .system_info import get_system_info
from .ai_engine import AIEngine


__all__ = ["get_system_info", "AIEngine"]
