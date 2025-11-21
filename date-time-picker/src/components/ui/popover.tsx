import * as React from "react"
import { cn } from "@/lib/utils"

interface PopoverProps {
  children: React.ReactNode
  open?: boolean
  onOpenChange?: (open: boolean) => void
}

interface PopoverTriggerProps {
  children: React.ReactNode
  asChild?: boolean
}

interface PopoverContentProps extends React.HTMLAttributes<HTMLDivElement> {
  children: React.ReactNode
  align?: 'start' | 'center' | 'end'
  sideOffset?: number
}

const PopoverContext = React.createContext<{
  open: boolean
  setOpen: (open: boolean) => void
  triggerRef: React.RefObject<HTMLElement>
}>({
  open: false,
  setOpen: () => {},
  triggerRef: { current: null },
})

export function Popover({ children, open: controlledOpen, onOpenChange }: PopoverProps) {
  const [internalOpen, setInternalOpen] = React.useState(false)
  const triggerRef = React.useRef<HTMLElement>(null)
  
  const open = controlledOpen !== undefined ? controlledOpen : internalOpen
  const setOpen = (newOpen: boolean) => {
    if (controlledOpen === undefined) {
      setInternalOpen(newOpen)
    }
    onOpenChange?.(newOpen)
  }

  React.useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (triggerRef.current && !triggerRef.current.contains(event.target as Node)) {
        const popoverContent = document.querySelector('[data-popover-content]')
        if (popoverContent && !popoverContent.contains(event.target as Node)) {
          setOpen(false)
        }
      }
    }

    if (open) {
      document.addEventListener('mousedown', handleClickOutside)
      return () => document.removeEventListener('mousedown', handleClickOutside)
    }
  }, [open])

  return (
    <PopoverContext.Provider value={{ open, setOpen, triggerRef }}>
      {children}
    </PopoverContext.Provider>
  )
}

export function PopoverTrigger({ children, asChild }: PopoverTriggerProps) {
  const { setOpen, triggerRef } = React.useContext(PopoverContext)
  
  const handleClick = () => setOpen(true)
  
  if (asChild && React.isValidElement(children)) {
    return React.cloneElement(children as React.ReactElement<any>, {
      ref: triggerRef,
      onClick: handleClick,
    })
  }
  
  return (
    <div ref={triggerRef as React.RefObject<HTMLDivElement>} onClick={handleClick}>
      {children}
    </div>
  )
}

export function PopoverContent({ 
  children, 
  className, 
  align = 'center',
  sideOffset = 4,
  ...props 
}: PopoverContentProps) {
  const { open, triggerRef } = React.useContext(PopoverContext)
  const [position, setPosition] = React.useState({ top: 0, left: 0 })
  const contentRef = React.useRef<HTMLDivElement>(null)

  React.useEffect(() => {
    if (open && triggerRef.current && contentRef.current) {
      const triggerRect = triggerRef.current.getBoundingClientRect()
      const contentRect = contentRef.current.getBoundingClientRect()
      
      let left = triggerRect.left
      if (align === 'center') {
        left = triggerRect.left + (triggerRect.width - contentRect.width) / 2
      } else if (align === 'end') {
        left = triggerRect.right - contentRect.width
      }
      
      setPosition({
        top: triggerRect.bottom + sideOffset,
        left: Math.max(10, Math.min(left, window.innerWidth - contentRect.width - 10)),
      })
    }
  }, [open, align, sideOffset])

  if (!open) return null

  return (
    <div
      ref={contentRef}
      data-popover-content
      className={cn(
        "fixed z-50 rounded-lg border border-border bg-background p-4 shadow-lg",
        className
      )}
      style={{
        top: `${position.top}px`,
        left: `${position.left}px`,
      }}
      {...props}
    >
      {children}
    </div>
  )
}