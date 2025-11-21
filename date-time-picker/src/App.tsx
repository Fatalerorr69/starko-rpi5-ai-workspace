import { useState } from 'react'
import { DateTimePicker } from './components/DateTimePicker'
import './App.css'

function App() {
  const [selectedDate, setSelectedDate] = useState<Date>(new Date(2023, 10, 30, 12, 0))

  return (
    <div className="min-h-screen bg-background flex items-center justify-center p-8">
      <div className="w-full max-w-md">
        <DateTimePicker 
          value={selectedDate} 
          onChange={setSelectedDate}
        />
      </div>
    </div>
  )
}

export default App
