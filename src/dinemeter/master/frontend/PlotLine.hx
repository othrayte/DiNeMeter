package dinemeter.master.frontend;

import easelhx.display.Shape;
import haxe.SHA1;

/**
 * ...
 * @author Adrian Cowan (othrayte)
 */

class PlotLine extends Shape {
    var colour:String;
    var type:String;
    
	var width:Float;
	var height:Float;
    
    public function new(colour:Int, width:Float, height:Float, type:String) {
        super();
        this.colour = "#"+StringTools.hex(colour,6);
        this.width = width;
        this.height = height;
        this.type = type;
    }
    
    public function display(orderedData:Array<DataRecord>, start:Int, now:Int, end:Int, vScale:Float, hScale:Float) {
        graphics.clear();
        switch (type) {
            case "down":
                graphics.beginStroke(colour).moveTo(1, height - orderedData[0].down*(height/vScale));
                for (i in 1 ... orderedData.length) {
                    graphics.lineTo(i*hScale + 1, height - orderedData[i].down * (height/vScale));
                }
                graphics.endStroke();
            case "up":
                graphics.beginStroke(colour).moveTo(1, height - orderedData[0].up*(height/vScale));
                for (i in 1 ... orderedData.length) {
                    graphics.lineTo(i*hScale + 1, height - orderedData[i].up * (height/vScale));
                }
                graphics.endStroke();
            case "uDown":
                graphics.beginStroke(colour).moveTo(1, height - orderedData[0].uDown*(height/vScale));
                for (i in 1 ... orderedData.length) {
                    graphics.lineTo(i*hScale + 1, height - orderedData[i].uDown * (height/vScale));
                }
                graphics.endStroke();
            case "uUp":
                graphics.beginStroke(colour).moveTo(1, height - orderedData[0].uUp*(height/vScale));
                for (i in 1 ... orderedData.length) {
                    graphics.lineTo(i*hScale + 1, height - orderedData[i].uUp * (height/vScale));
                }
                graphics.endStroke();
        }
    }
}