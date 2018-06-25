//
//  RubberBandUtils.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 5/9/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation

class RubberBandUtils {
    
    let NEXT_RULE_VALUE             : Int = 2
    var mainGetFrameList            : [Int] = []
    var isRuleBreaker               : Bool = false
    var rulesArray                  : [Int] = []
    var nextFrame                   : Int = 0
    var rules                       : Int = 1
    
    init(){
        mainGetFrameList = []
    }
    
    func getIndexToReplace(framesList : [FrameData],
        numImagesToCapture : Int,
        frameNum : Int ) -> Int {
        
        mainGetFrameList = getCurrentFrames( numBins: numImagesToCapture,
            totalNumFrames: frameNum )
        
        for frameData in framesList {
            if( !mainGetFrameList.contains(frameData.frameNum!) ){
                return indexOf( framesList: framesList, requestedFrameData: frameData )
            }
                
        }
        return -1
    }


    func indexOf( framesList : [FrameData],
                  requestedFrameData : FrameData ) -> Int {
        var index = 0
        for frameData in framesList {
            /*
                Android code does framesList.indexOf( frameData)
                indexOf uses Java equals for the frameData object hashCode comparison.
                So for the analagous Swift functionality we use == rather than ===
            */
            if( frameData == requestedFrameData ) {
                break
            }
            else{
                index = index + 1
            }
            
        } // for
        return index
    }
    
    func getCurrentFrames( numBins : Int, totalNumFrames : Int ) -> [Int]{
        var currentFrameList            : [Int] = []
        for index in 0...numBins-1 {
            currentFrameList.append(index)
        }
        
        rules = 1; // by default we start from rule 1
        // get the number of current frames
        nextFrame = currentFrameList.count - 1;
        rulesArray.append(rules)
        // top level rubberBandResult is not used
        _ = rubberBand(currentFrames: &currentFrameList,
                   totalNumFrames: totalNumFrames)
        return currentFrameList
    }
    
    
    func rubberBand( currentFrames : inout [Int],
                     totalNumFrames : Int ) -> [Int]{
        var counter : Int = 0;
        while (counter < rulesArray.count){
            
            for i in 0...currentFrames.count-1 {
                isRuleBreaker = false;
                if( currentFrames[i] % rulesArray[counter] != 0 ) {
                    nextFrame = nextFrame + 1
                    currentFrames[i] = nextFrame
                    isRuleBreaker = true;
                    break; // break out of for loop
                } // if
            } // for
            
            // Sort currentFrames in ascending order
            currentFrames.sort()
            
            /*
             Check next frame equal to total number of frames then return list
             (It is for testing purpose, need to be replaced with Smile Threshold)
            */
            if (totalNumFrames == nextFrame) {
                isRuleBreaker = false;
                return currentFrames;
            }
            
            /* If total number of frames is not equal next frame,
             rule break is not meeting then go to next rule */
            if (totalNumFrames != nextFrame &&
                !isRuleBreaker &&
                counter == rulesArray.count - 1 ) {
                /* add next rule */
                rules = rules * NEXT_RULE_VALUE;
                rulesArray.append(rules);
                break; // break out of while loop
            }
            
            if( !isRuleBreaker ){
                // if lowest rule is satisfied then we go next rule
                counter = counter + 1
            }
            else{
                //  check the all frames again until lowest rule is not satisfying
                counter = 0;
            }
            
            
        } // while
        
        // here is check total number of frame equal to next frame then return list
        if (totalNumFrames == nextFrame) {
            isRuleBreaker = false;
            return currentFrames;
        }
        else {
            isRuleBreaker = false;
            return rubberBand(currentFrames: &currentFrames, totalNumFrames: totalNumFrames); // Recursion
        }
        
        
    }
    
    
    
    
    
}
