package dinemeter.master.frontend;

import dinemeter.DataList;
import dinemeter.DataRecord;
import dinemeter.DataMath;
import js.Lib;
import js.DomCanvas;

import easelhx.display.Stage;
import easelhx.display.Shape;
import easelhx.display.Text;

using Lambda;
using dinemeter.DataRecord;


/**
 *  This file is part of DiNeMeterMaster.
 *
 *  DiNeMeterMaster is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU Affero General Public License as
 *  published by the Free Software Foundation, either version 3 of the
 *  License, or any later version.
 *
 *  DiNeMeterMaster is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU Affero General Public License for more details.
 *
 *  You should have received a copy of the GNU Affero General Public License
 *  along with DiNeMeterMaster.  If not, see <http://www.gnu.org/licenses/>.
 *
 * @author othrayte
 */

class UsageGraph {
	var canvas:DomCanvas;
	var stage:Stage;
	var bg:Shape;
	var downLines:Hash<PlotLine>;
	var upLines:Hash<PlotLine>;
	var uDownLines:Hash<PlotLine>;
	var uUpLines:Hash<PlotLine>;
    
    var vScaleText:Array<Text>;
    var hScaleText:Array<Text>;
    
    var colours:Array<Int>;
    
	var width:Float;
	var height:Float;
	
    var graphWidth:Float;
	var graphHeight:Float;
	
	var dScale:Float;
	var uScale:Float;
	
	public function new(id:String) {
		canvas = cast Lib.document.getElementById(id);
		stage = new Stage(canvas);
		
        colours = [0xCD1E14, 0x12D6EB, 0x4BCE13, 0xF8F103, 0xC94E18, 0x1879E4, 0x82C61C, 0xF0DF0B, 0xCD7514, 0x1279EB, 0x24BD30, 0xFBC900];
        
        downLines = new Hash();
        upLines = new Hash();
        uDownLines = new Hash();
        uUpLines = new Hash();
        
        vScaleText = new Array();
        hScaleText = new Array();
        
		width = canvas.width;
		height = canvas.height;
        
        graphWidth = width - 50;
        graphHeight = height - 40;
		
		bg = new Shape();
		
		stage.addChild(bg);
		
		stage.tick();
	}
    
    public function setup(usernames:Array<String>) {
        for (username in usernames) {
            var dPL = new PlotLine(colours.shift(), graphWidth, graphHeight, "down");
            downLines.set(username, dPL);
            dPL.x = 50;
            stage.addChild(dPL);
            var uPL = new PlotLine(colours.shift(), graphWidth, graphHeight, "up");
            upLines.set(username, uPL);
            uPL.x = 50;
            stage.addChild(uPL);
            var uDPL = new PlotLine(colours.shift(), graphWidth, graphHeight, "uDown");
            uDownLines.set(username, uDPL);
            uDPL.x = 50;
            stage.addChild(uDPL);
            var uUPL = new PlotLine(colours.shift(), graphWidth, graphHeight, "uUp");
            uUpLines.set(username, uUPL);
            uUPL.x = 50;
            stage.addChild(uUPL);
        }
    }
    
	public function display(data:Hash<DataList<DataRecord>>, start:Int, now:Int , end:Int) {
        if ((now - start) < 3 * 24 * 60 * 60) {
            end = 3 * 24 * 60 * 60;
        } else {
            end = now;
        }
		var res:Int = 3*60*60;
        var hScale:Float = graphWidth / ((end-start)/res);
        var vScale:Float = (res * 2 * 1024 * 1024) / hScale;
        
        bg.graphics.clear();
        drawAxis();
        drawScales(start, end, vScale);
        
        for (username in data.keys()) {
            var dl = data.get(username);
            var vals:DataList<DataRecord> = dl.refactor(start, now+res, res);
            var sorted:Array<DataRecord> = new Array();
            for (item in vals) {
                sorted[Math.round((item.start - start) / res)] = item;
            }
            for (i in 0 ... sorted.length) {
                if (sorted[i] == null) sorted[i] = new DataRecord();
            }
            if (downLines.exists(username)) downLines.get(username).display(sorted, start, now, end, vScale, hScale);
            if (upLines.exists(username)) upLines.get(username).display(sorted, start, now, end, vScale, hScale);
            if (uDownLines.exists(username)) uDownLines.get(username).display(sorted, start, now, end, vScale, hScale);
            if (uUpLines.exists(username)) uUpLines.get(username).display(sorted, start, now, end, vScale, hScale);
        }
		
		stage.tick();
	}
	
    private function drawAxis() {
        bg.graphics.setStrokeStyle(1);
        bg.graphics.beginStroke("black");
        bg.graphics.moveTo(50, 0);
        bg.graphics.lineTo(50, height);
        bg.graphics.endStroke();
        bg.graphics.beginStroke("black");
        bg.graphics.moveTo(50, graphHeight);
        bg.graphics.lineTo(width, graphHeight);
        bg.graphics.endStroke();
    }
    
    private function drawScales(start:Int, end:Int, vScale:Float) {
        bg.graphics.setStrokeStyle(1);
        var vDiv = (vScale / 8);
        var vDiv = Math.pow(2, Math.floor((Math.log(vDiv) / Math.log(2))));
        var vInc = graphHeight/(vScale/vDiv);
        for (y in 0 ... Math.floor(graphHeight/vInc)) {
            bg.graphics.beginStroke("black");
            bg.graphics.moveTo(50, graphHeight - y*vInc);
            bg.graphics.lineTo(45, graphHeight - y*vInc);
            bg.graphics.endStroke();
            bg.graphics.beginStroke("#DBDBDB");
            bg.graphics.moveTo(50, graphHeight - y*vInc);
            bg.graphics.lineTo(width, graphHeight - y*vInc);
            bg.graphics.endStroke();
            if (vScaleText[y] == null) {
                vScaleText[y] = new Text("empty", "sans serif", "black");
                stage.addChild(vScaleText[y]);
                vScaleText[y].x = 42;
                vScaleText[y].textAlign = "right";
                vScaleText[y].textBaseline = "middle";
            }
            vScaleText[y].text = DataMath.format(vDiv * y);
            vScaleText[y].y = graphHeight - y*vInc;
        }
        
        var hScale = end - start;
        var hDiv = (hScale / 8);
        var league:Int;
        var tStamp = Date.fromTime(start*1000);
        if (hDiv <= 60*60) {
            league = 1;
            tStamp = new Date(tStamp.getFullYear(), tStamp.getMonth(), tStamp.getDate(), tStamp.getHours(), tStamp.getMinutes(), 0);
        } else if (hDiv <= 24*60*60) {
            league = 2;
            tStamp = new Date(tStamp.getFullYear(), tStamp.getMonth(), tStamp.getDate(), tStamp.getHours(), 0, 0);
        } else if (hDiv <= 7*24*60*60) {
            league = 3;
            tStamp = new Date(tStamp.getFullYear(), tStamp.getMonth(), tStamp.getDate(), 0, 0, 0);
        } else {
            league = 4;
            tStamp = new Date(tStamp.getFullYear(), tStamp.getMonth(), 1, 0, 0, 0);
        }
        
        var xC = 0;
        var daysOfWeek = ["Sun", "Mon", "Tues", "Wed", "Thur", "Fri", "Sat"];
        var monthsOfYear = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
        while (tStamp.getTime() / 1000 < end) {
            var x = 50 + graphWidth * (tStamp.getTime() / 1000 - start) / hScale;
            if (x > 50) {
                bg.graphics.beginStroke("black");
                bg.graphics.moveTo(x, graphHeight);
                bg.graphics.lineTo(x, graphHeight + 5);
                bg.graphics.endStroke();
                if (hScaleText[xC] == null) {
                    hScaleText[xC] = new Text("empty", "sans serif", "black");
                    stage.addChild(hScaleText[xC]);
                    hScaleText[xC].y = graphHeight+10;
                    hScaleText[xC].textAlign = "left";
                    hScaleText[xC].textBaseline = "top";
                }
                if (league == 1) {
                    hScaleText[xC].text = DateTools.format(tStamp, "%I:%M %p");
                } else if (league == 2) {
                    hScaleText[xC].text = DateTools.format(tStamp, "%I %p");
                } else if (league == 3) {
                    hScaleText[xC].text = daysOfWeek[tStamp.getDay()]+"\n"+tStamp.getDate()+" "+monthsOfYear[tStamp.getMonth()];
                } else if (league == 4) {
                    hScaleText[xC].text = monthsOfYear[tStamp.getMonth()];
                }
                hScaleText[xC].x = x;
                xC++;
            }
            if (league == 1) {
                tStamp = new Date(tStamp.getFullYear(), tStamp.getMonth(), tStamp.getDate(), tStamp.getHours(), tStamp.getMinutes()+1, 0);
            } else if (league == 2) {
                tStamp = new Date(tStamp.getFullYear(), tStamp.getMonth(), tStamp.getDate(), tStamp.getHours()+1, 0, 0);
            } else if (league == 3) {
                tStamp = new Date(tStamp.getFullYear(), tStamp.getMonth(), tStamp.getDate()+1, 0, 0, 0);
            } else if (league == 4) {
                tStamp = new Date(tStamp.getFullYear(), tStamp.getMonth()+1, 1, 0, 0, 0);
            }
        }
        
    }
}