//
//  Rendering.swift
//  ConsoleChat
//
//  Created by Hayden Steele on 11/7/25.
//

import Foundation


func getTerminalSize() -> (Int, Int) {
    var ws = winsize()
    let ioctlResult = ioctl(STDOUT_FILENO, TIOCGWINSZ, &ws)
    if ioctlResult == -1 {
        print("Error: Unable to query terminal size.")
    }
    
    let termRows = Int(ws.ws_row)
    let cols = Int(ws.ws_col)
    
    if (termRows == 0 || cols == 0) {
        print("Error: Cannot get terminal size.")
    }
    
    return (termRows, cols)
}

func newBuffer(width: Int, height: Int) -> [[Character]] {
    return Array(repeating: Array(repeating: " ", count: width), count: height)
}

func printBuffer(_ buffer: inout [[Character]]) {
    for _ in 0...3 {
        print()
    }
    for line in buffer {
        print(String(line))
    }
}




func drawBox(_ buffer: inout [[Character]], x: Int, y: Int, width: Int, height: Int) {
    for yPos in stride(from: y, to: y + height + 1, by: 1) {
        for xPos in stride(from: x, to: x + width + 1, by: 1) {
            
            if (xPos < 0 || xPos >= buffer.first!.count) { continue }
            if (yPos < 0 || yPos >= buffer.count) {
                // Extend the buffer if overflow downward
                buffer.append(Array(repeating: " ", count: buffer.first!.count))
            }
            
            if (xPos == x && yPos == y) {
                buffer[yPos][xPos] = "┌"
                continue
            }
            if (xPos == x + width && yPos == y) {
                buffer[yPos][xPos] = "┐"
                continue
            }
            
            if (xPos == x && yPos == y + height) {
                buffer[yPos][xPos] = "└"
                continue
            }
            
            if (xPos == x + width && yPos == y + height) {
                buffer[yPos][xPos] = "┘"
                continue
            }
            
            if (yPos == y || yPos == y + height) {
                buffer[yPos][xPos] = "─"
                continue
            }
            
            if (xPos == x || xPos == x + width) {
                buffer[yPos][xPos] = "│"
                continue
            }
            
            
        }
    }
}

func drawWrappedText(_ buffer: inout [[Character]], wrappedText: WrappedText, x: Int, y: Int) {
    for yShift in 0..<wrappedText.height {
        for xShift in 0..<wrappedText.lines[yShift].count {
            
            if (x + xShift >= buffer.first!.count || y + yShift >= buffer.count) { continue; }
            if (yShift >= wrappedText.lines.count || xShift >= wrappedText.lines[yShift].count) { continue; }
            
            
            buffer[yShift + y][xShift + x] = wrappedText.lines[yShift][xShift]
            
        }
    }
}
func drawWrappedText(_ buffer: inout [[Character]], text: String, x: Int, y: Int, maxWidth: Int) {
    let wrappedText = calcWrappedText(text: text, maxWidth: maxWidth)
    drawWrappedText(&buffer, wrappedText: wrappedText, x: x, y: y)
}

struct WrappedText {
    let lines: [[Character]]
    let height: Int
    let width: Int
}
func calcWrappedText(text: String, maxWidth: Int) -> WrappedText {
    
    var lines: [String] = []
    
    for line in text.split(separator: "\n") {
        lines.append("")
        for word in line.split(separator: " ") {
            if (word.first?.isNewline ?? false) {
                lines.append("")
            }
            
            if (word.count + lines.last!.count > maxWidth) {
                lines.append("")
            }
            
            lines[lines.count - 1] += "\(word.trimmingCharacters(in: .init(charactersIn: " \t"))) "
            
            if (word.last?.isNewline ?? false) {
                lines.append("")
            }
        }
    }
    
    return WrappedText(
        lines: lines.map { Array($0) },
        height: lines.count,
        width: lines.map { $0.count }.max() ?? 0
    )
}



func drawTextInBox(_ buffer: inout [[Character]], text: String, header: String? = nil, x: Int, y: Int, width: Int, padding: Int = 1) -> (Int, Int) {
    let wrappedText = calcWrappedText(text: text, maxWidth: width - 2 - 2 * padding)
    let headerShift = header == nil ? 0 : 1
    
    drawBox(&buffer, x: x, y: y, width: width, height: wrappedText.height + 1 + padding * 2 + headerShift)
    
    drawWrappedText(&buffer, wrappedText: wrappedText, x: x + padding + 1, y: y + padding + 1 + headerShift)
    if (header != nil) {
        drawWrappedText(&buffer, text: header!, x: x + padding + 1, y: y + padding + 1, maxWidth: width)
    }
    return (width, wrappedText.height + 1 + padding * 2 + headerShift)
}


