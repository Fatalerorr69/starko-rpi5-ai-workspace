import { useState } from 'react'
import { Calendar, Clock } from 'lucide-react'
import { format, startOfMonth, endOfMonth, eachDayOfInterval, isSameMonth, isSameDay, addMonths, subMonths, startOfWeek, endOfWeek } from 'date-fns'
import { Button } from './ui/button'
import { Popover, PopoverTrigger, PopoverContent } from './ui/popover'
import { cn } from '@/lib/utils'

const YEARS = [2021, 2022, 2023, 2024, 2025, 2026]
const WEEKDAYS = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']

interface DateTimePickerProps {
  value?: Date
  onChange?: (date: Date) => void
}

export function DateTimePicker({ value, onChange }: DateTimePickerProps) {
  const [open, setOpen] = useState(false)
  const [selectedDate, setSelectedDate] = useState<Date>(value || new Date())
  const [currentMonth, setCurrentMonth] = useState<Date>(value || new Date())
  const [selectedTime, setSelectedTime] = useState<string>(
    value ? format(value, 'HH:mm') : '12:00'
  )

  const today = new Date()

  const handleDateSelect = (date: Date) => {
    const [hours, minutes] = selectedTime.split(':').map(Number)
    const newDate = new Date(date)
    newDate.setHours(hours, minutes)
    setSelectedDate(newDate)
    onChange?.(newDate)
  }

  const handleToday = () => {
    const now = new Date()
    setSelectedDate(now)
    setCurrentMonth(now)
    setSelectedTime(format(now, 'HH:mm'))
    onChange?.(now)
    setOpen(false)
  }

  const handleCancel = () => {
    setOpen(false)
  }

  const handleYearClick = (year: number) => {
    const newDate = new Date(currentMonth)
    newDate.setFullYear(year)
    setCurrentMonth(newDate)
  }

  const renderMonth = (monthOffset: number) => {
    const month = addMonths(currentMonth, monthOffset)
    const monthStart = startOfMonth(month)
    const monthEnd = endOfMonth(month)
    const startDate = startOfWeek(monthStart)
    const endDate = endOfWeek(monthEnd)
    
    const days = eachDayOfInterval({ start: startDate, end: endDate })

    return (
      <div key={monthOffset} className="mb-8">
        <h3 className="text-lg font-semibold text-center mb-4">
          {format(month, 'MMMM yyyy')}
        </h3>
        
        <div className="grid grid-cols-7 gap-1 mb-2">
          {WEEKDAYS.map((day) => (
            <div key={day} className="text-center text-sm text-muted-foreground font-medium py-2">
              {day}
            </div>
          ))}
        </div>
        
        <div className="grid grid-cols-7 gap-1">
          {days.map((day, idx) => {
            const isCurrentMonth = isSameMonth(day, month)
            const isSelected = isSameDay(day, selectedDate)
            const isToday = isSameDay(day, today)
            
            return (
              <button
                key={idx}
                onClick={() => isCurrentMonth && handleDateSelect(day)}
                disabled={!isCurrentMonth}
                className={cn(
                  "h-10 w-10 rounded-lg text-sm font-medium transition-colors",
                  "hover:bg-muted focus:outline-none",
                  !isCurrentMonth && "text-muted-foreground/40 cursor-default hover:bg-transparent",
                  isCurrentMonth && "text-foreground",
                  isSelected && "bg-primary text-primary-foreground hover:bg-primary",
                  isToday && !isSelected && "underline underline-offset-2"
                )}
              >
                {format(day, 'd')}
              </button>
            )
          })}
        </div>
      </div>
    )
  }

  return (
    <div className="space-y-4">
      <Popover open={open} onOpenChange={setOpen}>
        <PopoverTrigger asChild>
          <Button variant="default" size="lg" className="text-base">
            Add Date and Time
          </Button>
        </PopoverTrigger>
        
        <PopoverContent className="w-auto p-0" align="start">
          <div className="flex gap-4 p-4 border-b border-border">
            <div className="flex items-center gap-2 bg-muted px-4 py-2 rounded-lg flex-1">
              <input
                type="text"
                value={format(selectedDate, 'dd/MM/yyyy')}
                readOnly
                className="bg-transparent border-none outline-none text-sm font-medium w-28"
              />
              <Calendar className="w-5 h-5 text-muted-foreground" />
            </div>
            
            <div className="flex items-center gap-2 bg-muted px-4 py-2 rounded-lg">
              <input
                type="time"
                value={selectedTime}
                onChange={(e) => setSelectedTime(e.target.value)}
                className="bg-transparent border-none outline-none text-sm font-medium w-16"
              />
              <Clock className="w-5 h-5 text-muted-foreground" />
            </div>
          </div>
          
          <div className="flex">
            <div className="flex-1 p-4 max-h-96 overflow-y-auto">
              {renderMonth(0)}
              {renderMonth(1)}
            </div>
            
            <div className="w-20 border-l border-border p-4 flex flex-col items-center gap-3 overflow-y-auto max-h-96">
              {YEARS.map((year) => (
                <button
                  key={year}
                  onClick={() => handleYearClick(year)}
                  className={cn(
                    "text-sm font-medium transition-colors hover:text-primary",
                    currentMonth.getFullYear() === year
                      ? "text-primary font-bold"
                      : "text-muted-foreground"
                  )}
                >
                  {year}
                </button>
              ))}
            </div>
          </div>
          
          <div className="flex justify-between items-center p-4 border-t border-border">
            <Button variant="ghost" onClick={handleToday} className="text-primary">
              Today
            </Button>
            <Button variant="ghost" onClick={handleCancel} className="text-primary">
              Cancel
            </Button>
          </div>
        </PopoverContent>
      </Popover>
      
      <div className="flex gap-4">
        <div className="flex items-center gap-2 bg-muted px-4 py-2 rounded-lg flex-1">
          <input
            type="text"
            value={format(selectedDate, 'dd/MM/yyyy')}
            readOnly
            className="bg-transparent border-none outline-none text-sm font-medium w-28"
          />
          <Calendar className="w-5 h-5 text-muted-foreground" />
        </div>
        
        <div className="flex items-center gap-2 bg-muted px-4 py-2 rounded-lg">
          <input
            type="time"
            value={selectedTime}
            onChange={(e) => setSelectedTime(e.target.value)}
            className="bg-transparent border-none outline-none text-sm font-medium w-16"
          />
          <Clock className="w-5 h-5 text-muted-foreground" />
        </div>
      </div>
    </div>
  )
}