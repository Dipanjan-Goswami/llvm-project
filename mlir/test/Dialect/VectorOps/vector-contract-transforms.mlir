// RUN: mlir-opt %s -test-vector-contraction-conversion | FileCheck %s

#dotp_accesses = [
  affine_map<(i) -> (i)>,
  affine_map<(i) -> (i)>,
  affine_map<(i) -> ()>
]
#dotp_trait = {
  indexing_maps = #dotp_accesses,
  iterator_types = ["reduction"]
}

// CHECK-LABEL: func @extract_contract1
// CHECK-SAME: %[[A:.*0]]: vector<4xf32>,
// CHECK-SAME: %[[B:.*1]]: vector<4xf32>,
// CHECK-SAME: %[[C:.*2]]: f32
// CHECK:      %[[Z:.*]] = constant dense<0.000000e+00> : vector<4xf32>
// CHECK:      %[[F:.*]] = vector.fma %[[A]], %[[B]], %[[Z]] : vector<4xf32>
// CHECK:      %[[R:.*]] = vector.reduction "add", %[[F]], %[[C]] : vector<4xf32> into f32
// CHECK:      return %[[R]] : f32

func @extract_contract1(%arg0: vector<4xf32>, %arg1: vector<4xf32>, %arg2: f32) -> f32 {
  %0 = vector.contract #dotp_trait %arg0, %arg1, %arg2
    : vector<4xf32>, vector<4xf32> into f32
  return %0 : f32
}

#matvec_accesses = [
  affine_map<(i, j) -> (i, j)>,
  affine_map<(i, j) -> (j)>,
  affine_map<(i, j) -> (i)>
]
#matvec_trait = {
  indexing_maps = #matvec_accesses,
  iterator_types = ["parallel", "reduction"]
}

// CHECK-LABEL: func @extract_contract2
// CHECK-SAME: %[[A:.*0]]: vector<2x3xf32>,
// CHECK-SAME: %[[B:.*1]]: vector<3xf32>,
// CHECK-SAME: %[[C:.*2]]: vector<2xf32>
// CHECK:      %[[R:.*]] = constant dense<0.000000e+00> : vector<2xf32>
// CHECK:      %[[Z:.*]] = constant dense<0.000000e+00> : vector<3xf32>
// CHECK:      %[[T0:.*]] = vector.extract %[[A]][0] : vector<2x3xf32>
// CHECK:      %[[T1:.*]] = vector.extract %[[C]][0] : vector<2xf32>
// CHECK:      %[[T2:.*]] = vector.fma %[[T0]], %[[B]], %[[Z]] : vector<3xf32>
// CHECK:      %[[T3:.*]] = vector.reduction "add", %[[T2]], %[[T1]] : vector<3xf32> into f32
// CHECK:      %[[T4:.*]] = vector.insert %[[T3]], %[[R]] [0] : f32 into vector<2xf32>
// CHECK:      %[[T5:.*]] = vector.extract %[[A]][1] : vector<2x3xf32>
// CHECK:      %[[T6:.*]] = vector.extract %[[C]][1] : vector<2xf32>
// CHECK:      %[[T7:.*]] = vector.fma %[[T5]], %[[B]], %[[Z]] : vector<3xf32>
// CHECK:      %[[T8:.*]] = vector.reduction "add", %[[T7]], %[[T6]] : vector<3xf32> into f32
// CHECK:      %[[T9:.*]] = vector.insert %[[T8]], %[[T4]] [1] : f32 into vector<2xf32>
// CHECK:      return %[[T9]] : vector<2xf32>

func @extract_contract2(%arg0: vector<2x3xf32>,
                        %arg1: vector<3xf32>,
			%arg2: vector<2xf32>) -> vector<2xf32> {
  %0 = vector.contract #matvec_trait %arg0, %arg1, %arg2
    : vector<2x3xf32>, vector<3xf32> into vector<2xf32>
  return %0 : vector<2xf32>
}

#vecmat_accesses = [
  affine_map<(i, j) -> (j)>,
  affine_map<(i, j) -> (i, j)>,
  affine_map<(i, j) -> (i)>
]
#vecmat_trait = {
  indexing_maps = #vecmat_accesses,
  iterator_types = ["parallel", "reduction"]
}

// CHECK-LABEL: func @extract_contract3
// CHECK-SAME: %[[A:.*0]]: vector<3xf32>,
// CHECK-SAME: %[[B:.*1]]: vector<2x3xf32>,
// CHECK-SAME: %[[C:.*2]]: vector<2xf32>
// CHECK:      %[[R:.*]] = constant dense<0.000000e+00> : vector<2xf32>
// CHECK:      %[[Z:.*]] = constant dense<0.000000e+00> : vector<3xf32>
// CHECK:      %[[T0:.*]] = vector.extract %[[B]][0] : vector<2x3xf32>
// CHECK:      %[[T1:.*]] = vector.extract %[[C]][0] : vector<2xf32>
// CHECK:      %[[T2:.*]] = vector.fma %[[A]], %[[T0]], %[[Z]] : vector<3xf32>
// CHECK:      %[[T3:.*]] = vector.reduction "add", %[[T2]], %[[T1]] : vector<3xf32> into f32
// CHECK:      %[[T4:.*]] = vector.insert %[[T3]], %[[R]] [0] : f32 into vector<2xf32>
// CHECK:      %[[T5:.*]] = vector.extract %[[B]][1] : vector<2x3xf32>
// CHECK:      %[[T6:.*]] = vector.extract %[[C]][1] : vector<2xf32>
// CHECK:      %[[T7:.*]] = vector.fma %[[A]], %[[T5]], %[[Z]] : vector<3xf32>
// CHECK:      %[[T8:.*]] = vector.reduction "add", %[[T7]], %[[T6]] : vector<3xf32> into f32
// CHECK:      %[[T9:.*]] = vector.insert %[[T8]], %[[T4]] [1] : f32 into vector<2xf32>
// CHECK:      return %[[T9]] : vector<2xf32>

func @extract_contract3(%arg0: vector<3xf32>,
                        %arg1: vector<2x3xf32>,
                        %arg2: vector<2xf32>) -> vector<2xf32> {
  %0 = vector.contract #vecmat_trait %arg0, %arg1, %arg2
    : vector<3xf32>, vector<2x3xf32> into vector<2xf32>
  return %0 : vector<2xf32>
}

#matmat_accesses = [
  affine_map<(i, j, k) -> (i, k)>,
  affine_map<(i, j, k) -> (k, j)>,
  affine_map<(i, j, k) -> (i, j)>
]
#matmat_trait = {
  indexing_maps = #matmat_accesses,
  iterator_types = ["parallel", "parallel", "reduction"]
}

// CHECK-LABEL: func @extract_contract4
// CHECK-SAME: %[[A:.*0]]: vector<2x2xf32>,
// CHECK-SAME: %[[B:.*1]]: vector<2x2xf32>,
// CHECK-SAME: %[[C:.*2]]: vector<2x2xf32>
// CHECK:    %[[R:.*]] = constant dense<0.000000e+00> : vector<2x2xf32>
// CHECK:    %[[Z:.*]] = constant dense<0.000000e+00> : vector<2xf32>
// CHECK:    %[[T0:.*]] = vector.extract %[[A]][0] : vector<2x2xf32>
// CHECK:    %[[T1:.*]] = vector.extract %[[C]][0] : vector<2x2xf32>
// CHECK:    %[[T2:.*]] = vector.extract %[[B]][0] : vector<2x2xf32>
// CHECK:    %[[T3:.*]] = vector.extract %[[T2]][0] : vector<2xf32>
// CHECK:    %[[T4:.*]] = vector.insert %[[T3]], %[[Z]] [0] : f32 into vector<2xf32>
// CHECK:    %[[T5:.*]] = vector.extract %[[B]][1] : vector<2x2xf32>
// CHECK:    %[[T6:.*]] = vector.extract %[[T5]][0] : vector<2xf32>
// CHECK:    %[[T7:.*]] = vector.insert %[[T6]], %[[T4]] [1] : f32 into vector<2xf32>
// CHECK:    %[[T8:.*]] = vector.extract %[[T1]][0] : vector<2xf32>
// CHECK:    %[[T9:.*]] = vector.fma %[[T0]], %[[T7]], %[[Z]] : vector<2xf32>
// CHECK:    %[[T10:.*]] = vector.reduction "add", %[[T9]], %[[T8]] : vector<2xf32> into f32
// CHECK:    %[[T11:.*]] = vector.insert %[[T10]], %[[Z]] [0] : f32 into vector<2xf32>
// CHECK:    %[[T12:.*]] = vector.extract %[[B]][0] : vector<2x2xf32>
// CHECK:    %[[T13:.*]] = vector.extract %[[T12]][1] : vector<2xf32>
// CHECK:    %[[T14:.*]] = vector.insert %[[T13]], %[[Z]] [0] : f32 into vector<2xf32>
// CHECK:    %[[T15:.*]] = vector.extract %[[B]][1] : vector<2x2xf32>
// CHECK:    %[[T16:.*]] = vector.extract %[[T15]][1] : vector<2xf32>
// CHECK:    %[[T17:.*]] = vector.insert %[[T16]], %[[T14]] [1] : f32 into vector<2xf32>
// CHECK:    %[[T18:.*]] = vector.extract %[[T1]][1] : vector<2xf32>
// CHECK:    %[[T19:.*]] = vector.fma %[[T0]], %[[T17]], %[[Z]] : vector<2xf32>
// CHECK:    %[[T20:.*]] = vector.reduction "add", %[[T19]], %[[T18]] : vector<2xf32> into f32
// CHECK:    %[[T21:.*]] = vector.insert %[[T20]], %[[T11]] [1] : f32 into vector<2xf32>
// CHECK:    %[[T22:.*]] = vector.insert %[[T21]], %[[R]] [0] : vector<2xf32> into vector<2x2xf32>
// CHECK:    %[[T23:.*]] = vector.extract %[[A]][1] : vector<2x2xf32>
// CHECK:    %[[T24:.*]] = vector.extract %[[C]][1] : vector<2x2xf32>
// CHECK:    %[[T25:.*]] = vector.extract %[[B]][0] : vector<2x2xf32>
// CHECK:    %[[T26:.*]] = vector.extract %[[T25]][0] : vector<2xf32>
// CHECK:    %[[T27:.*]] = vector.insert %[[T26]], %[[Z]] [0] : f32 into vector<2xf32>
// CHECK:    %[[T28:.*]] = vector.extract %[[B]][1] : vector<2x2xf32>
// CHECK:    %[[T29:.*]] = vector.extract %[[T28]][0] : vector<2xf32>
// CHECK:    %[[T30:.*]] = vector.insert %[[T29]], %[[T27]] [1] : f32 into vector<2xf32>
// CHECK:    %[[T31:.*]] = vector.extract %[[T24]][0] : vector<2xf32>
// CHECK:    %[[T32:.*]] = vector.fma %[[T23]], %[[T30]], %[[Z]] : vector<2xf32>
// CHECK:    %[[T33:.*]] = vector.reduction "add", %[[T32]], %[[T31]] : vector<2xf32> into f32
// CHECK:    %[[T34:.*]] = vector.insert %[[T33]], %[[Z]] [0] : f32 into vector<2xf32>
// CHECK:    %[[T35:.*]] = vector.extract %[[B]][0] : vector<2x2xf32>
// CHECK:    %[[T36:.*]] = vector.extract %[[T35]][1] : vector<2xf32>
// CHECK:    %[[T37:.*]] = vector.insert %[[T36]], %[[Z]] [0] : f32 into vector<2xf32>
// CHECK:    %[[T38:.*]] = vector.extract %[[B]][1] : vector<2x2xf32>
// CHECK:    %[[T39:.*]] = vector.extract %[[T38]][1] : vector<2xf32>
// CHECK:    %[[T40:.*]] = vector.insert %[[T39]], %[[T37]] [1] : f32 into vector<2xf32>
// CHECK:    %[[T41:.*]] = vector.extract %[[T24]][1] : vector<2xf32>
// CHECK:    %[[T42:.*]] = vector.fma %[[T23]], %[[T40]], %[[Z]] : vector<2xf32>
// CHECK:    %[[T43:.*]] = vector.reduction "add", %[[T42]], %[[T41]] : vector<2xf32> into f32
// CHECK:    %[[T44:.*]] = vector.insert %[[T43]], %[[T34]] [1] : f32 into vector<2xf32>
// CHECK:    %[[T45:.*]] = vector.insert %[[T44]], %[[T22]] [1] : vector<2xf32> into vector<2x2xf32>
// CHECK:    return %[[T45]] : vector<2x2xf32>

func @extract_contract4(%arg0: vector<2x2xf32>,
                        %arg1: vector<2x2xf32>,
                        %arg2: vector<2x2xf32>) -> vector<2x2xf32> {
  %0 = vector.contract #matmat_trait %arg0, %arg1, %arg2
    : vector<2x2xf32>, vector<2x2xf32> into vector<2x2xf32>
  return %0 : vector<2x2xf32>
}

#contraction2d_accesses = [
  affine_map<(i, j) -> (i, j)>,
  affine_map<(i, j) -> (i, j)>,
  affine_map<(i, j) -> ()>
]
#contraction2d_trait = {
  indexing_maps = #contraction2d_accesses,
  iterator_types = ["reduction", "reduction"]
}

// CHECK-LABEL: func @full_contract1
// CHECK-SAME: %[[A:.*0]]: vector<2x3xf32>,
// CHECK-SAME: %[[B:.*1]]: vector<2x3xf32>,
// CHECK-SAME: %[[C:.*2]]: f32
// CHECK:      %[[Z:.*]] = constant dense<0.000000e+00> : vector<3xf32>
// CHECK:      %[[T0:.*]] = vector.extract %[[A]][0] : vector<2x3xf32>
// CHECK:      %[[T1:.*]] = vector.extract %[[B]][0] : vector<2x3xf32>
// CHECK:      %[[T2:.*]] = vector.fma %[[T0]], %[[T1]], %[[Z]] : vector<3xf32>
// CHECK:      %[[T3:.*]] = vector.reduction "add", %[[T2]], %[[C]] : vector<3xf32> into f32
// CHECK:      %[[T4:.*]] = vector.extract %[[A]][1] : vector<2x3xf32>
// CHECK:      %[[T5:.*]] = vector.extract %[[B]][1] : vector<2x3xf32>
// CHECK:      %[[T6:.*]] = vector.fma %[[T4]], %[[T5]], %[[Z]] : vector<3xf32>
// CHECK:      %[[T7:.*]] = vector.reduction "add", %[[T6]], %[[T3]] : vector<3xf32> into f32
// CHECK:      return %[[T7]] : f32

func @full_contract1(%arg0: vector<2x3xf32>,
                     %arg1: vector<2x3xf32>,
		     %arg2: f32) -> f32 {
  %0 = vector.contract #contraction2d_trait %arg0, %arg1, %arg2
    : vector<2x3xf32>, vector<2x3xf32> into f32
  return %0 : f32
}

#contraction2d_trans_accesses = [
  affine_map<(i, j) -> (i, j)>,
  affine_map<(i, j) -> (j, i)>,
  affine_map<(i, j) -> ()>
]
#contraction2d_trans_trait = {
  indexing_maps = #contraction2d_trans_accesses,
  iterator_types = ["reduction", "reduction"]
}

// CHECK-LABEL: func @full_contract2
// CHECK-SAME: %[[A:.*0]]: vector<2x3xf32>,
// CHECK-SAME: %[[B:.*1]]: vector<3x2xf32>,
// CHECK-SAME: %[[C:.*2]]: f32
// CHECK:      %[[Z:.*]] = constant dense<0.000000e+00> : vector<3xf32>
// CHECK:      %[[T0:.*]] = vector.extract %[[A]][0] : vector<2x3xf32>
// CHECK:      %[[T1:.*]] = vector.extract %[[B]][0] : vector<3x2xf32>
// CHECK:      %[[T2:.*]] = vector.extract %[[T1]][0] : vector<2xf32>
// CHECK:      %[[T3:.*]] = vector.insert %[[T2]], %[[Z]] [0] : f32 into vector<3xf32>
// CHECK:      %[[T4:.*]] = vector.extract %[[B]][1] : vector<3x2xf32>
// CHECK:      %[[T5:.*]] = vector.extract %[[T4]][0] : vector<2xf32>
// CHECK:      %[[T6:.*]] = vector.insert %[[T5]], %[[T3]] [1] : f32 into vector<3xf32>
// CHECK:      %[[T7:.*]] = vector.extract %[[B]][2] : vector<3x2xf32>
// CHECK:      %[[T8:.*]] = vector.extract %[[T7]][0] : vector<2xf32>
// CHECK:      %[[T9:.*]] = vector.insert %[[T8]], %[[T6]] [2] : f32 into vector<3xf32>
// CHECK:      %[[T10:.*]] = vector.fma %[[T0]], %[[T9]], %[[Z]] : vector<3xf32>
// CHECK:      %[[T11:.*]] = vector.reduction "add", %[[T10]], %[[C]] : vector<3xf32> into f32
// CHECK:      %[[T12:.*]] = vector.extract %[[A]][1] : vector<2x3xf32>
// CHECK:      %[[T13:.*]] = vector.extract %[[B]][0] : vector<3x2xf32>
// CHECK:      %[[T14:.*]] = vector.extract %[[T13]][1] : vector<2xf32>
// CHECK:      %[[T15:.*]] = vector.insert %[[T14]], %[[Z]] [0] : f32 into vector<3xf32>
// CHECK:      %[[T16:.*]] = vector.extract %[[B]][1] : vector<3x2xf32>
// CHECK:      %[[T17:.*]] = vector.extract %[[T16]][1] : vector<2xf32>
// CHECK:      %[[T18:.*]] = vector.insert %[[T17]], %[[T15]] [1] : f32 into vector<3xf32>
// CHECK:      %[[T19:.*]] = vector.extract %[[B]][2] : vector<3x2xf32>
// CHECK:      %[[T20:.*]] = vector.extract %[[T19]][1] : vector<2xf32>
// CHECK:      %[[T21:.*]] = vector.insert %[[T20]], %[[T18]] [2] : f32 into vector<3xf32>
// CHECK:      %[[T22:.*]] = vector.fma %[[T12]], %[[T21]], %[[Z]] : vector<3xf32>
// CHECK:      %[[T23:.*]] = vector.reduction "add", %[[T22]], %[[T11]] : vector<3xf32> into f32
// CHECK:      return %[[T23]] : f32

func @full_contract2(%arg0: vector<2x3xf32>,
                     %arg1: vector<3x2xf32>,
		     %arg2: f32) -> f32 {
  %0 = vector.contract #contraction2d_trans_trait %arg0, %arg1, %arg2
    : vector<2x3xf32>, vector<3x2xf32> into f32
  return %0 : f32
}

// Shape up and downcasts for 2-D vectors, for supporting conversion to
// llvm.matrix operations
// CHECK-LABEL: func @shape_casts
func @shape_casts(%a: vector<2x2xf32>) -> (vector<4xf32>, vector<2x2xf32>) {
  // CHECK: %[[cst:.*]] = constant dense<0.000000e+00> : vector<4xf32>
  // CHECK: %[[cst22:.*]] = constant dense<0.000000e+00> : vector<2x2xf32>
  // CHECK: %[[ex0:.*]] = vector.extract %{{.*}}[0] : vector<2x2xf32>
  //
  // CHECK: %[[in0:.*]] = vector.insert_strided_slice %[[ex0]], %[[cst]]
  // CHECK-SAME: {offsets = [0], strides = [1]} : vector<2xf32> into vector<4xf32>
  //
  // CHECK: %[[ex1:.*]] = vector.extract %{{.*}}[1] : vector<2x2xf32>
  //
  // CHECK: %[[in2:.*]] = vector.insert_strided_slice %[[ex1]], %[[in0]]
  // CHECK-SAME: {offsets = [2], strides = [1]} : vector<2xf32> into vector<4xf32>
  //
  %0 = vector.shape_cast %a : vector<2x2xf32> to vector<4xf32>
  // CHECK: %[[add:.*]] = addf %[[in2]], %[[in2]] : vector<4xf32>
  %r0 = addf %0, %0: vector<4xf32>
  //
  // CHECK: %[[ss0:.*]] = vector.strided_slice %[[add]]
  // CHECK-SAME: {offsets = [0], sizes = [2], strides = [1]} :
  // CHECK-SAME: vector<4xf32> to vector<2xf32>
  //
  // CHECK: %[[res0:.*]] = vector.insert %[[ss0]], %[[cst22]] [0] :
  // CHECK-SAME: vector<2xf32> into vector<2x2xf32>
  //
  // CHECK: %[[s2:.*]] = vector.strided_slice %[[add]]
  // CHECK-SAME: {offsets = [2], sizes = [2], strides = [1]} :
  // CHECK-SAME: vector<4xf32> to vector<2xf32>
  //
  // CHECK: %[[res1:.*]] = vector.insert %[[s2]], %[[res0]] [1] :
  // CHECK-SAME: vector<2xf32> into vector<2x2xf32>
  //
  %1 = vector.shape_cast %r0  : vector<4xf32> to vector<2x2xf32>
  // CHECK: return %[[add]], %[[res1]] : vector<4xf32>, vector<2x2xf32>
  return %r0, %1 : vector<4xf32>, vector<2x2xf32>
}
